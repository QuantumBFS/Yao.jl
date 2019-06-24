export Rotor, generator, Diff, backward!, gradient, CPhaseGate, DiffBlock
import Yao: expect, content, chcontent, mat, apply!
using StatsBase

############# General Rotor ############
const Rotor{N, T} = Union{RotationGate{N, T}, PutBlock{N, <:Any, <:RotationGate{<:Any, T}}}
const CphaseGate{N, T} = ControlBlock{N,<:ShiftGate{T},<:Any}
const DiffBlock{N, T} = Union{Rotor{N, T}, CphaseGate{N, T}}
"""
    generator(rot::Rotor) -> AbstractBlock

Return the generator of rotation block.
"""
generator(rot::RotationGate) = rot.block
generator(rot::PutBlock{N, C, GT}) where {N, C, GT<:RotationGate} = PutBlock{N}(generator(rot|>content), rot |> occupied_locs)
generator(c::CphaseGate{N}) where N = ControlBlock{N}(c.ctrl_locs, c.ctrl_config, Z, c.locs)

#################### The Basic Diff #################
"""
    Diff{GT, N, T} <: TagBlock{GT, N}
    Diff(block) -> Diff

Mark a block as quantum differentiable.
"""
mutable struct Diff{GT, N, T} <: TagBlock{GT, N}
    block::GT
    grad::T
    Diff(block::DiffBlock{N, T}) where {N, T} = new{typeof(block), N, T}(block, T(0))
end
content(cb::Diff) = cb.block
chcontent(cb::Diff, blk::DiffBlock) = Diff(blk)

istraitkeeper(::Diff) = Val(true)

@forward Diff.block apply!
mat(::Type{T}, df::Diff) where T = mat(T, df.block)
Base.adjoint(df::Diff) = chcontent(df, content(df)')

function YaoBlocks.print_annotation(io::IO, df::Diff)
    printstyled(io, "[∂] "; bold=true, color=:yellow)
end

#### interface #####
export autodiff, numdiff, opdiff, StatFunctional, statdiff, as_weights

as_weights(probs::AbstractVector{T}) where T = Weights(probs, T(1))
"""
    autodiff(mode::Symbol, block::AbstractBlock) -> AbstractBlock
    autodiff(mode::Symbol) -> Function

automatically mark differentiable items in a block tree as differentiable.
"""
function autodiff end
autodiff(mode::Symbol) = block->autodiff(mode, block)
autodiff(mode::Symbol, block::AbstractBlock) = autodiff(Val(mode), block)

# for BP
autodiff(::Val{:BP}, block::DiffBlock) = Diff(block)
autodiff(::Val{:BP}, block::AbstractBlock) = block
# Sequential, Roller and ChainBlock can propagate.
function autodiff(mode::Val{:BP}, blk::Union{ChainBlock, Sequential})
    chsubblocks(blk, autodiff.(mode, subblocks(blk)))
end

# for QC
autodiff(::Val{:QC}, block::Union{RotationGate, CphaseGate}) = Diff(block)
# escape control blocks.
autodiff(::Val{:QC}, block::ControlBlock) = block

function autodiff(mode::Val{:QC}, blk::AbstractBlock)
    blks = subblocks(blk)
    isempty(blks) ? blk : chsubblocks(blk, autodiff.(mode, blks))
end

@inline function _perturb(func, gate::Diff{<:DiffBlock}, δ::Real)
    dispatch!(-, gate, (δ,))
    r1 = func()
    dispatch!(+, gate, (2δ,))
    r2 = func()
    dispatch!(-, gate, (δ,))
    r1, r2
end

@inline function _perturb(func, gate::Diff{<:Rotor}, δ::Real)  # for put
    dispatch!(-, gate, (δ,))
    r1 = func()
    dispatch!(+, gate, (2δ,))
    r2 = func()
    dispatch!(-, gate, (δ,))
    r1, r2
end

"""
    numdiff(loss, diffblock::Diff; δ::Real=1e-2)

Numeric differentiation.
"""
@inline function numdiff(loss, diffblock::Diff; δ::Real=1e-2)
    r1, r2 = _perturb(loss, diffblock, δ)
    diffblock.grad = (r2 - r1)/2δ
end

"""
    opdiff(psifunc, diffblock::Diff, op::AbstractBlock)

Operator differentiation.
"""
@inline function opdiff(psifunc, diffblock::Diff, op::AbstractBlock)
    r1, r2 = _perturb(()->expect(op, psifunc()) |> real, diffblock, π/2)
    diffblock.grad = (r2 - r1)/2
end

"""
    StatFunctional{N, AT}
    StatFunctional(array::AT<:Array) -> StatFunctional{N, <:Array}
    StatFunctional{N}(func::AT<:Function) -> StatFunctional{N, <:Function}

statistic functional, i.e.
    * if `AT` is an array, A[i,j,k...], it is defined on finite Hilbert space, which is `∫A[i,j,k...]p[i]p[j]p[k]...`
    * if `AT` is a function, F(xᵢ,xⱼ,xₖ...), this functional is `1/C(r,n)... ∑ᵢⱼₖ...F(xᵢ,xⱼ,xₖ...)`, see U-statistics for detail.

References:
    U-statistics, http://personal.psu.edu/drh20/asymp/fall2006/lectures/ANGELchpt10.pdf
"""
struct StatFunctional{N, AT}
    data::AT
    StatFunctional{N}(data::AT) where {N, AT<:Function} = new{N, AT}(data)
    StatFunctional(data::AT) where {N, AT<:AbstractArray{<:Real, N}} = new{N, AT}(data)
end

@forward StatFunctional.data Base.ndims
Base.parent(stat::StatFunctional) = stat.data

expect(stat::StatFunctional{2, <:AbstractArray}, px::Weights, py::Weights=px) = px.values' * stat.data * py.values
expect(stat::StatFunctional{1, <:AbstractArray}, px::Weights) = stat.data' * px.values
function expect(stat::StatFunctional{2, <:Function}, xs::AbstractVector{T}) where T
    N = length(xs)
    res = zero(stat.data(xs[1], xs[1]))
    for i = 2:N
        for j = 1:i-1
            @inbounds res += stat.data(xs[i], xs[j])
        end
    end
    res/binomial(N,2)
end
function expect(stat::StatFunctional{2, <:Function}, xs::AbstractVector, ys::AbstractVector)
    M = length(xs)
    N = length(ys)
    ci = CartesianIndices((M, N))
    @inbounds mapreduce(ind->stat.data(xs[ind[1]], ys[ind[2]]), +, ci)/M/N
end
expect(stat::StatFunctional{1, <:Function}, xs::AbstractVector) = mean(stat.data.(xs))
Base.ndims(stat::StatFunctional{N}) where N = N

"""
    statdiff(probfunc, diffblock::Diff, stat::StatFunctional{<:Any, <:AbstractArray}; initial::AbstractVector=probfunc())
    statdiff(samplefunc, diffblock::Diff, stat::StatFunctional{<:Any, <:Function}; initial::AbstractVector=samplefunc())

Differentiation for statistic functionals.
"""
@inline function statdiff(probfunc, diffblock::Diff, stat::StatFunctional{2}; initial::AbstractVector=probfunc())
    r1, r2 = _perturb(()->expect(stat, probfunc(), initial), diffblock, π/2)
    diffblock.grad = (r2 - r1)*ndims(stat)/2
end
@inline function statdiff(probfunc, diffblock::Diff, stat::StatFunctional{1})
    r1, r2 = _perturb(()->expect(stat, probfunc()), diffblock, π/2)
    diffblock.grad = (r2 - r1)*ndims(stat)/2
end

"""
    backward!(state, circuit::AbstractBlock) -> AbstractRegister

back propagate and calculate the gradient ∂f/∂θ = 2*Re(∂f/∂ψ*⋅∂ψ*/∂θ), given ∂f/∂ψ*.
`state` is a pair of output_register => the corresponding adjoint.

Note:
Here, the input circuit should be a matrix block, otherwise the back propagate may not apply (like Measure operations).
"""
function backward!(state, block::AbstractBlock)
    out, outδ = state
    adjblock = block'
    backward_params!((out, outδ), block)
    in = apply!(out, adjblock)
    inδ = apply!(outδ, adjblock)
    return (in, inδ)
end

function backward!(state, circuit::Union{ChainBlock, Concentrator})
    for blk in Base.Iterators.reverse(subblocks(circuit))
        state = backward!(state, blk)
    end
    return state
end

backward!(state, block::Measure) = throw(MethodError(backward!, (state, block)))

backward_params!(state, block::AbstractBlock) = nothing
function backward_params!(state, block::Diff{<:DiffBlock})
    in, outδ = state
    Σ = generator(content(block))
    block.grad = -statevec(in |> Σ)' * statevec(outδ) |> imag
    in |> Σ
    nothing
end

"""
    gradient(circuit::AbstractBlock, mode::Symbol=:ANY) -> Vector

collect all gradients in a circuit, mode can be :BP/:QC/:ANY, they will collect `grad` from Diff respectively.
"""
gradient(circuit::AbstractBlock) = gradient!(circuit, parameters_eltype(circuit)[])

function gradient!(circuit::AbstractBlock, grad)
    for block in subblocks(circuit)
        gradient!(block, grad)
    end
    grad
end

gradient!(circuit::Diff, grad) = append!(grad, circuit.grad)
