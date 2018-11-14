export autodiff, numdiff, opdiff, StatFunctional, statdiff

"""
    autodiff(mode::Symbol, block::AbstractBlock) -> AbstractBlock
    autodiff(mode::Symbol) -> Function

automatically mark differentiable items in a block tree as differentiable.
"""
function autodiff end
autodiff(mode::Symbol) = block->autodiff(mode, block)
autodiff(mode::Symbol, block::AbstractBlock) = autodiff(Val(mode), block)

# for BP
autodiff(::Val{:BP}, block::Rotor{N}) where N = BPDiff(block)
autodiff(::Val{:BP}, block::AbstractBlock) = block
# Sequential, Roller and ChainBlock can propagate.
function autodiff(mode::Val{:BP}, blk::Union{ChainBlock, Roller, Sequential})
    chsubblocks(blk, autodiff.(mode, subblocks(blk)))
end

# for QC
autodiff(::Val{:QC}, block::RotationGate) = QDiff(block)
# escape control blocks.
autodiff(::Val{:QC}, block::ControlBlock) = block
function autodiff(mode::Val{:QC}, blk::AbstractBlock)
    chsubblocks(blk, autodiff.(mode, subblocks(blk)))
end

@inline function _perturb(func, gate::AbstractDiff{<:RotationGate}, δ::Real)
    setiparameters!(-, gate |> parent, δ)
    r1 = func()
    setiparameters!(+, gate |> parent, 2δ)
    r2 = func()
    setiparameters!(-, gate |> parent, δ)
    r1, r2
end

@inline function _perturb(func, gate::AbstractDiff{<:Rotor}, δ::Real)  # for put
    dispatch!(-, gate |> parent, [δ])
    r1 = func()
    dispatch!(+, gate |> parent, [2δ])
    r2 = func()
    dispatch!(-, gate |> parent, [δ])
    r1, r2
end

"""
    numdiff(loss, diffblock::AbstractDiff; δ::Real=1e-2)

Numeric differentiation.
"""
@inline function numdiff(loss, diffblock::AbstractDiff; δ::Real=1e-2)
    r1, r2 = _perturb(loss, diffblock, δ)
    diffblock.grad = (r2 - r1)/2δ
end

"""
    opdiff(psifunc, diffblock::AbstractDiff, op::MatrixBlock)

Operator differentiation.
"""
@inline function opdiff(psifunc, diffblock::AbstractDiff, op::MatrixBlock)
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

import Yao.Blocks: expect
using Yao.Interfaces: _perturb
expect(stat::StatFunctional{2, <:AbstractArray}, px::AbstractVector, py::AbstractVector=px) = px' * stat.data * py
expect(stat::StatFunctional{1, <:AbstractArray}, px::AbstractVector) = stat.data' * px
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
    statdiff(probfunc, diffblock::AbstractDiff, stat::StatFunctional{<:Any, <:AbstractArray}; initial::AbstractVector=probfunc())
    statdiff(samplefunc, diffblock::AbstractDiff, stat::StatFunctional{<:Any, <:Function}; initial::AbstractVector=samplefunc())

Differentiation for statistic functionals.
"""
@inline function statdiff(probfunc, diffblock::AbstractDiff, stat::StatFunctional{2}; initial::AbstractVector=probfunc())
    r1, r2 = _perturb(()->expect(stat, probfunc(), initial), diffblock, π/2)
    diffblock.grad = (r2 - r1)*ndims(stat)/2
end
@inline function statdiff(probfunc, diffblock::AbstractDiff, stat::StatFunctional{1})
    r1, r2 = _perturb(()->expect(stat, probfunc()), diffblock, π/2)
    diffblock.grad = (r2 - r1)*ndims(stat)/2
end

export scale, staticscale

scale(blk::MatrixBlock, x::Number) = Scale(blk, x)
scale(x::Number) = blk -> scale(blk, x)

staticscale(blk::MatrixBlock, x::Number) = StaticScale(blk, x)
staticscale(x::Number) = blk -> staticscale(blk, x)
include("Cache.jl")
