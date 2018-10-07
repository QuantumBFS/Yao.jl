export autodiff, numdiff, exactdiff

"""
    autodiff(block::AbstractBlock) -> AbstractBlock

automatically mark differentiable items in a block tree as differentiable.
"""
function autodiff end
autodiff(mode::Symbol) = block->autodiff(mode, block)
autodiff(mode::Symbol, block::AbstractBlock) = autodiff(Val(mode), block)

# for BP
autodiff(::Val{:BP}, block::Rotor{N}) where N = Diff(block)
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

@inline function _perturb(func, gate::QDiff, δ::Real)
    setiparameters!(+, gate |> parent, δ)
    r1 = func()
    setiparameters!(-, gate |> parent, 2δ)
    r2 = func()
    setiparameters!(+, gate |> parent, δ)
    r1, r2
end

@inline function numdiff(loss, diffblock::QDiff; δ::Real=1e-2)
    r1, r2 = _perturb(loss, diffblock, δ)
    diffblock.grad = (r2 - r1)/2δ
end

@inline function exactdiff(loss, diffblock::QDiff)
    r1, r2 = _perturb(loss, diffblock, π/2)
    diffblock.grad = (r2 - r1)/2
end

include("Cache.jl")
