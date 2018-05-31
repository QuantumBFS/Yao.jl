"""
    ChainBlock{N, T} <: CompositeBlock{N, T}

`ChainBlock` is a basic construct tool to create
user defined blocks horizontically. It is a `Vector`
like composite type.
"""
struct ChainBlock{N, T} <: CompositeBlock{N, T}
    blocks::Vector{MatrixBlock}

    function ChainBlock{N, T}(blocks::Vector) where {N, T}
        new{N, T}(blocks)
    end

    # type promotion
    function ChainBlock(blocks::Vector{<:MatrixBlock{N}}) where N
        T = promote_type(collect(datatype(each) for each in blocks)...)
        new{N, T}(blocks)
    end
end

function ChainBlock(blocks::MatrixBlock{N}...) where N
    ChainBlock(collect(blocks))
end

function copy(c::ChainBlock{N, T}) where {N, T}
    ChainBlock{N, T}([copy(each) for each in c.blocks])
end

function similar(c::ChainBlock{N, T}) where {N, T}
    ChainBlock{N, T}(empty!(similar(c.blocks)))
end

# Block Properties
isunitary(c::ChainBlock) = all(isunitary, c.blocks)
isreflexive(c::ChainBlock) = all(isreflexive, c.blocks)
ishermitian(c::ChainBlock) = all(ishermitian, c.blocks)

mat(c::ChainBlock) = prod(x->mat(x), reverse(c.blocks))

# Additional Methods for Composite Blocks
getindex(c::ChainBlock, index) = getindex(c.blocks, index)

function setindex!(c::ChainBlock, val, index)
    0 < index || throw(BoundsError(c, index))

    @inbounds if index > lastindex(c.blocks)
        push!(c.blocks, val)
    else
        setindex!(c.blocks, val, index)
    end
end

import Compat: lastindex
lastindex(c::ChainBlock) = lastindex(c.blocks)

## Iterate contained blocks
start(c::ChainBlock) = start(c.blocks)
next(c::ChainBlock, st) = next(c.blocks, st)
done(c::ChainBlock, st) = done(c.blocks, st)
length(c::ChainBlock) = length(c.blocks)
eltype(c::ChainBlock) = eltype(c.blocks)
eachindex(c::ChainBlock) = eachindex(c.blocks)
blocks(c::ChainBlock) = c.blocks

# Additional Methods for Chain
import Base: push!, append!, prepend!
push!(c::ChainBlock, val::MatrixBlock) = (push!(c.blocks, val); c)
append!(c::ChainBlock, list) = (append!(c.blocks, list); c)
prepend!(c::ChainBlock, list) = (prepend!(c.blocks, list); c)

function apply!(r::Register, c::ChainBlock)
    for each in c
        apply!(r, each)
    end
    r
end
