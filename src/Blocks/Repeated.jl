export RepeatedBlock

mutable struct RepeatedBlock{GT<:MatrixBlock, N, MT} <: CompositeBlock{N, MT}
    block::GT
    lines::Vector{Int}

    function RepeatedBlock{N, T}(block::GT) where {N, T, GT <: MatrixBlock}
        new{GT, N, T}(block, Vector{Int}(1:N))
    end

    function RepeatedBlock{N, T}(block::GT, lines::Vector{Int}) where {N, T, GT <: MatrixBlock}
        new{GT, N, T}(block, lines)
    end
end

start(c::RepeatedBlock) = start(c.lines)

function next(c::RepeatedBlock, st)
    line, st = next(c.lines, st)
    (line, c.block), st
end

done(c::RepeatedBlock, st) = done(c.lines, st)
length(c::RepeatedBlock) = length(c.lines)
eachindex(c::RepeatedBlock) = eachindex(c.lines)
getindex(c::RepeatedBlock, index) = c.block
blocks(rb::RepeatedBlock) = [rb.block]

copy(x::RepeatedBlock) = RepeatedBlock

dispatch!(f::Function, rb::RepeatedBlock, params...) = dispatch!(f, rb.block, params...)

function hash(rb::RepeatedBlock, h::UInt)
    hashkey = hash(objectid(rb), h)
    hashkey = hash(rb.block, hashkey)
    hashkey = hash(rb.lines, hashkey)
    hashkey
end

function ==(lhs::RepeatedBlock{BT, N, T}, rhs::RepeatedBlock{BT, N, T}) where {BT, N, T}
    (lhs.block == rhs.block) && (lhs.lines == rhs.lines)
end
