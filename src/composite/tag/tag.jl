export TagBlock

"""
    TagBlock{BT, N} <: AbstractContainer{BT, N}

`TagBlock` is a special kind of Container block, it forwards most of the methods
but tag the block with some extra information.
"""
abstract type TagBlock{BT, N} <: AbstractContainer{BT, N} end

# forward content properties
cache_key(tb::TagBlock) = cache_key(content(tb))
occupied_locs(x::TagBlock) = occupied_locs(content(x))

Base.:(==)(a::TB, b::TB) where {TB<:TagBlock} = content(a) == content(b)
