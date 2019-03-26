@deprecate usedbits(block::AbstractBlock{N}) where N occupied_locs(block)

# Originally addrs means return the addression stored in a composite block
# this is not necessary since not all composite block store the address, e.g
# roller, etc.
# @deprecate addrs(block::AbstractBlock) occupied_locs(block)

# NOTE: block is frequently used as variable name, to make sure there is
#       no conflicts, this is commented.
# @deprecate block(x::AbstractContainer) = parent(x)
# @deprecate chblock(x::AbstractContainer, blk::AbstractBlock) = chsubblocks(x, blk)
