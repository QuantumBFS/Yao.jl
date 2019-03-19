export TagBlock

"""
    TagBlock{N, T} <: AbstractContainer{N, T}

`TagBlock` is a special kind of Container block, it forwards most of the methods
but tag the block with some extra information.
"""
abstract type TagBlock{N, T} <: AbstractContainer{N, T} end

cache_key(tb::TagBlock) = cache_key(parent(tb))
occupied_locations(x::TagBlock) = occupied_locations(parent(x))

Base.:(==)(a::TB, b::TB) where {TB<:TagBlock} = parent(a) == parent(b)
Base.getindex(c::TagBlock, index...) = getindex(parent(c), index...)
Base.setindex!(c::TagBlock, val, index...) = setindex!(parent(c), val, index...)
Base.iterate(c::TagBlock) = iterate(parent(c))
Base.iterate(c::TagBlock, st) = iterate(parent(c), st)
