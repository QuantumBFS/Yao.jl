export TagBlock
"""
    TagBlock{N, T} <: AbstractContainer{N, T}

TagBlock is a special kind of Container, it is a size keeper.
"""
abstract type TagBlock{N, T} <: AbstractContainer{N, T} end

Base.:(==)(a::TB, b::TB) where {TB<:TagBlock} = parent(a) == parent(b)
Base.getindex(c::TagBlock, index...) = getindex(parent(c), index...)
Base.setindex!(c::TagBlock, val, index...) = setindex!(parent(c), val, index...)

Base.iterate(c::TagBlock) = iterate(parent(c))
Base.iterate(c::TagBlock, st) = iterate(parent(c), st)

cache_key(tb::TagBlock) = cache_key(parent(tb))
block(tb::TagBlock) = parent(tb)

include("BlockCache.jl")
include("Daggered.jl")
include("Scale.jl")

########## common interfaces are defined here! ##############
for BLOCKTYPE in (:Daggered, :CachedBlock, :StaticScale, :Scale)
    @eval Base.parent(dg::$BLOCKTYPE) = dg.block
end

for METHOD in (:usedbits,)
    @eval $METHOD(dg::TagBlock) = $METHOD(parent(dg))
end
