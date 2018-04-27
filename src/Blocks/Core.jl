abstract type AbstractBlock{N} end

# properties
nqubit(block::AbstractBlock{N}) where N = N

# methods
apply!(block::AbstractBlock, reg::AbstractRegister, head::Integer) = reg
update!(block::AbstractBlock, params...) = block

import Base: full, sparse
full(block::AbstractBlock) = full(Complex128, block)
sparse(block::AbstractBlock) = sparse(Complex128, block)
full(::Type{T}, block::AbstractBlock{N}) where {T, N} = eye(T, N)
sparse(::Type{T}, block::AbstractBlock{N}) where {T, N} = speye(T, N)

abstract type LeafBlock{N} <: AbstractBlock{N} end

"""
    IBlock{N} <: LeafBlock{N}

Identity block on N qubits. It is also the identity
of the set of `AbstractBlock`s.
"""
struct IBlock{N} <: LeafBlock{N}
end

IBlock(n::Integer) = IBlock{n}()
IBlock() = IBlock(1)
one(block::AbstractBlock{N}) where N = IBlock(N)
