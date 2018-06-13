export RepeatedBlock

"""
    RepeatedBlock{N, T, GT} <: CompositeBlock{N, T}

repeat the same block on given addrs.
"""
mutable struct RepeatedBlock{N, T, GT<:MatrixBlock} <: CompositeBlock{N, T}
    block::GT
    addrs::Vector{Int}

    function RepeatedBlock{N, T, GT}(block, addrs) where {N, M, T, GT<:MatrixBlock{M, T}}
        _assert_addr_safe(N, [i:i+M-1 for i in addrs])
        new{N, T, GT}(block, addrs)
    end
end

function RepeatedBlock{N}(block::GT) where {N, M, T, GT <: MatrixBlock{M, T}}
    RepeatedBlock{N, T, GT}(block, Vector{Int}(1:M:N-M+1))
end

function RepeatedBlock{N}(block::GT, addrs::Vector{Int}) where {N, M, T, GT <: MatrixBlock{M, T}}
    RepeatedBlock{N, T, GT}(block, addrs)
end

blocks(rb::RepeatedBlock) = [rb.block]
copy(x::RepeatedBlock) = typeof(x)(block, copy(x.addrs))

dispatch!(rb::RepeatedBlock, params...) = dispatch!(rb.block, params...)
dispatch!(f::Function, rb::RepeatedBlock, params...) = dispatch!(f, rb.block, params...)

function hash(rb::RepeatedBlock, h::UInt)
    hashkey = hash(objectid(rb), h)
    hashkey = hash(rb.block, hashkey)
    hashkey = hash(rb.addrs, hashkey)
    hashkey
end

function ==(lhs::RepeatedBlock{N, T, GT}, rhs::RepeatedBlock{N, T, GT}) where {N, T, GT}
    (lhs.block == rhs.block) && (lhs.addrs == rhs.addrs)
end

function cache_key(rb::RepeatedBlock)
    cache_key(rb.block)
end

function print_block(io::IO, rb::RepeatedBlock{N}) where N
    printstyled(io, "repeat on ("; bold=true, color=color(RepeatedBlock))
    for i in eachindex(rb.addrs)
        printstyled(io, rb.addrs[i]; bold=true, color=color(RepeatedBlock))
        if i != lastindex(rb.addrs)
            printstyled(io, ", "; bold=true, color=color(RepeatedBlock))
        end
    end
    printstyled(io, ")"; bold=true, color=color(RepeatedBlock))
end
