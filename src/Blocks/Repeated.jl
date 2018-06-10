export RepeatedBlock

mutable struct RepeatedBlock{N, T, GT<:MatrixBlock} <: CompositeBlock{N, T}
    block::GT
    lines::Vector{Int}

    function RepeatedBlock{N}(block::GT) where {N, M, T, GT <: MatrixBlock{M, T}}
        new{N, T, GT}(block, Vector{Int}(1:N))
    end

    function RepeatedBlock{N}(block::GT, lines::Vector{Int}) where {N, M, T, GT <: MatrixBlock{M, T}}
        new{N, T, GT}(block, lines)
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

dispatch!(rb::RepeatedBlock, params...) = dispatch!(rb.block, params...)
dispatch!(f::Function, rb::RepeatedBlock, params...) = dispatch!(f, rb.block, params...)

function hash(rb::RepeatedBlock, h::UInt)
    hashkey = hash(objectid(rb), h)
    hashkey = hash(rb.block, hashkey)
    hashkey = hash(rb.lines, hashkey)
    hashkey
end

function ==(lhs::RepeatedBlock{N, T, GT}, rhs::RepeatedBlock{N, T, GT}) where {N, T, GT}
    (lhs.block == rhs.block) && (lhs.lines == rhs.lines)
end

function cache_key(rb::RepeatedBlock)
    cache_key(rb.block)
end

function print_block(io::IO, rb::RepeatedBlock{N}) where N
    printstyled(io, "repeat on ("; bold=true, color=color(RepeatedBlock))
    for i in eachindex(rb.lines)
        printstyled(io, rb.lines[i]; bold=true, color=color(RepeatedBlock))
        if i != lastindex(rb.lines)
            printstyled(io, ", "; bold=true, color=color(RepeatedBlock))
        end
    end
    printstyled(io, ")"; bold=true, color=color(RepeatedBlock))
end
