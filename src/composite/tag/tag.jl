export TagBlock

"""
    TagBlock{BT, N, T} <: AbstractContainer{BT, N, T}

`TagBlock` is a special kind of Container block, it forwards most of the methods
but tag the block with some extra information.
"""
abstract type TagBlock{BT, N, T} <: AbstractContainer{BT, N, T} end

cache_key(tb::TagBlock) = cache_key(content(tb))
occupied_locs(x::TagBlock) = occupied_locs(content(x))

Base.:(==)(a::TB, b::TB) where {TB<:TagBlock} = content(a) == content(b)
Base.getindex(c::TagBlock, index...) = getindex(content(c), index...)
Base.setindex!(c::TagBlock, val, index...) = setindex!(content(c), val, index...)
Base.iterate(c::TagBlock) = iterate(content(c))
Base.iterate(c::TagBlock, st) = iterate(content(c), st)
