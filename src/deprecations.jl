using YaoBase
using BitBasis: BitStr
# NOTE: this file should only exists in v0.4.x
#       since in v0.4.x the conponent packages
#       are all new packages and should not have
#       deprecation warning itself.

# Base
@deprecate addbit!(r::AbstractRegister, n::Int) increase!(r, n)
@deprecate addbit!(n::Int) increase!(n)
@deprecate reset!(r::AbstractRegister; val::Integer=0)  collapseto!(r, val)
@deprecate measure_reset!(r::AbstractRegister; val::Int=0) measure_collapseto!(r; config=val)
@deprecate measure_reset!(r::AbstractRegister, locs; val::Int=0) measure_collapseto!(r, locs; config=val)

# ArrayReg
@deprecate register(raw::AbstractMatrix; B=size(raw,2)) ArrayReg{B}(raw)
@deprecate register(raw::AbstractVector) ArrayReg(raw)
@deprecate register(bits::BitStr, nbatch::Int=1) ArrayReg{nbatch}(bits)
@deprecate register(::Type{T}, bits::BitStr, nbatch::Int) where T ArrayReg{nbatch}(T, bits)

@deprecate usedbits(block::AbstractBlock{N}) where N occupied_locs(block)

# Originally addrs means return the addression stored in a composite block
# this is not necessary since not all composite block store the address, e.g
# roller, etc.
# @deprecate addrs(block::AbstractBlock) occupied_locs(block)

# NOTE: block is frequently used as variable name, to make sure there is
#       no conflicts, this is commented.
# @deprecate block(x::AbstractContainer) = parent(x)
# @deprecate chblock(x::AbstractContainer, blk::AbstractBlock) = chsubblocks(x, blk)
