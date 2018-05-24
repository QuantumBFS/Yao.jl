export MatrixBlock

"""
    MatrixBlock{N, T} <: AbstractBlock

abstract type that all block with a matrix form will subtype from.

# extended APIs

`sparse`
`full`
`datatype`
"""
abstract type MatrixBlock{N, T} <: AbstractBlock end

nqubit(::MatrixBlock{N}) where N = N
ninput(::MatrixBlock{N}) where N = N
noutput(::MatrixBlock{N}) where N = N

ispure(block::MatrixBlock) = true
isunitary(block::MatrixBlock) = true

import Base: full, sparse, eltype
datatype(block::MatrixBlock{N, T}) where {N, T} = T
full(block::MatrixBlock) = full(sparse(block))

function apply!(reg::Register, b::MatrixBlock)
    reg.state .= sparse(b) * reg
    reg
end

include("Primitive.jl")
include("Composite.jl")
