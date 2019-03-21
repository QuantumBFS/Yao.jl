export TagBlock

"""
    TagBlock{N, T} <: AbstractContainer{N, T}

`TagBlock` is a special kind of Container block, it forwards most of the methods
but tag the block with some extra information.
"""
abstract type TagBlock{N, T, BT} <: AbstractContainer{N, T, BT} end

cache_key(tb::TagBlock) = cache_key(content(tb))
occupied_locations(x::TagBlock) = occupied_locations(content(x))

Base.:(==)(a::TB, b::TB) where {TB<:TagBlock} = content(a) == content(b)
Base.getindex(c::TagBlock, index...) = getindex(content(c), index...)
Base.setindex!(c::TagBlock, val, index...) = setindex!(content(c), val, index...)
Base.iterate(c::TagBlock) = iterate(content(c))
Base.iterate(c::TagBlock, st) = iterate(content(c), st)
