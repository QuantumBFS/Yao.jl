export autodiff

"""
    autodiff(block::AbstractBlock) -> AbstractBlock

automatically mark differentiable items in a block tree as differentiable.
"""
function autodiff end
autodiff(block::Rotor{N}) where N = Diff(block)
# control, repeat, kron, roller and Diff can not propagate.
autodiff(block::AbstractBlock) = block
function autodiff(blk::Union{ChainBlock, Roller, Sequential})
    chsubblocks(blk, autodiff.(subblocks(blk)))
end

include("Cache.jl")
