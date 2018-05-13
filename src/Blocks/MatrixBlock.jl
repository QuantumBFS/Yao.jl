"""
    MatrixBlock{N, T} <: AbstractBlock

abstract type that all block with a matrix form will subtype from.
"""
abstract type MatrixBlock{N, T} <: AbstractBlock end

nqubit(::Type{T}) where {N, T <: MatrixBlock{N}} = N
ninput(::Type{T}) where {N, T <: MatrixBlock{N}} = N
noutput(::Type{T}) where {N, T <: MatrixBlock{N}} = N

ispure(block::MatrixBlock) = true
isunitary(block::MatrixBlock) = true

import Base: full, sparse, eltype
eltype(block::MatrixBlock{N, T}) where {N, T} = T
full(block::MatrixBlock) = full(sparse(block))

function apply!(reg::Register, b::MatrixBlock)
    reg.state .= sparse(b) * reg
    reg
end

include("Primitive.jl")
include("Composite.jl")
