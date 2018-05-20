"""
    ChainBlock

`ChainBlock` is a basic construct tool to create
user defined blocks horizontically.
"""
struct ChainBlock{N, T} <: CompositeBlock{N, T}
    blocks::Vector{Any}
end

# Enable type promotion
function ChainBlock(n, blocks::Vector)
    T = promote_type(collect(datatype(each) for each in blocks)...)
    ChainBlock{n, T}(blocks)
end

function ChainBlock(blocks::Vector{MatrixBlock{N}}) where N
    ChainBlock(N, blocks)
end

function ChainBlock(blocks::MatrixBlock{N}...) where N
    ChainBlock(N, collect(blocks))
end

function copy(c::ChainBlock{N, T}) where {N, T}
    ChainBlock{N, T}(deepcopy(c.blocks))
end

function similar(c::ChainBlock{N, T}) where {N, T}
    ChainBlock{N, T}(similar(c.blocks))
end

# Block Properties
isunitary(c::ChainBlock) = all(isunitary, c.blocks)
isreflexive(c::ChainBlock) = all(isreflexive, c.blocks)
isunitary_hermitian(c::ChainBlock) = all(isunitary_hermitian, c.blocks)
ishermitian(c::ChainBlock) = all(ishermitian, c.blocks)

full(c::ChainBlock) = prod(x->full(x), reverse(c.blocks))
sparse(c::ChainBlock) = prod(x->sparse(x), reverse(c.blocks))

# Additional Methods for Composite Blocks
getindex(c::ChainBlock, index) = getindex(c.blocks, index)
setindex!(c::ChainBlock, val, index) = setindex!(c.blocks, val, index)

import Base: endof
endof(c::ChainBlock) = endof(c.blocks)

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

function show(io::IO, c::ChainBlock{N, T}) where {N, T}
    println(io, "ChainBlock{$N, $T}")
    for i in eachindex(c.blocks)
        if isassigned(c.blocks, i)
            print(io, "\t", c.blocks[i])
        else
            print(io, "\t", "#undef")
        end

        if i != endof(c.blocks)
            print(io, "\n")
        end
    end
end
