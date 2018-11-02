export autodiff, numdiff, opdiff, Vstat, vstatdiff

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
    Vstat{N, AT}
    Vstat(data) -> Vstat
    Vstat{N}(func) -> Vstat

V-statistic functional.
"""
struct Vstat{N, AT}
    data::AT
    Vstat{N}(data::AT) where {N, AT<:Function} = new{N, AT}(data)
    Vstat(data::AT) where {N, AT<:AbstractArray{<:Real, N}} = new{N, AT}(data)
end

@forward Vstat.data Base.ndims
Base.parent(vstat::Vstat) = vstat.data

import Yao.Blocks: expect
using Yao.Interfaces: _perturb
expect(vstat::Vstat{2, <:AbstractArray}, px::AbstractVector, py::AbstractVector=px) = px' * vstat.data * py
expect(vstat::Vstat{1, <:AbstractArray}, px::AbstractVector) = vstat.data' * px
expect(vstat::Vstat{2, <:Function}, xs::AbstractVector, ys::AbstractVector=xs) = mean(vstat.data.(xs', ys))
expect(vstat::Vstat{1, <:Function}, xs::AbstractVector) = mean(vstat.data.(xs))
Base.ndims(vstat::Vstat{N}) where N = N

"""
    vstatdiff(probfunc, diffblock::AbstractDiff, vstat::Vstat{<:Any, <:AbstractArray}; initial::AbstractVector=probfunc())
    vstatdiff(samplefunc, diffblock::AbstractDiff, vstat::Vstat{<:Any, <:Function}; initial::AbstractVector=samplefunc())

Differentiation for V-statistics.
"""
@inline function vstatdiff(probfunc, diffblock::AbstractDiff, vstat::Vstat{2}; initial::AbstractVector=probfunc())
    r1, r2 = _perturb(()->expect(vstat, probfunc(), initial), diffblock, π/2)
    diffblock.grad = (r2 - r1)*ndims(vstat)/2
end
@inline function vstatdiff(probfunc, diffblock::AbstractDiff, vstat::Vstat{1})
    r1, r2 = _perturb(()->expect(vstat, probfunc()), diffblock, π/2)
    diffblock.grad = (r2 - r1)*ndims(vstat)/2
end

export scale, staticscale

scale(blk::MatrixBlock, x::Number) = Scale(blk, x)
scale(x::Number) = blk -> scale(blk, x)

staticscale(blk::MatrixBlock, x::Number) = StaticScale(blk, x)
staticscale(x::Number) = blk -> staticscale(blk, x)
include("Cache.jl")
