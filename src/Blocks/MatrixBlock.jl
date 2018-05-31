import Base: hash, ==
export MatrixBlock, dense

"""
    MatrixBlock{N, T} <: AbstractBlock

abstract type that all block with a matrix form will subtype from.

# extended APIs

`mat`
`sparse`
`full`
`datatype`
"""
abstract type MatrixBlock{N, T} <: AbstractBlock end

nqubits(::Type{MT}) where {N, MT <: MatrixBlock{N}} = N
ninput(::Type{MT}) where {N, MT <: MatrixBlock{N}} = N
noutput(::Type{MT}) where {N, MT <: MatrixBlock{N}} = N

nqubits(::MatrixBlock{N}) where N = N
ninput(::MatrixBlock{N}) where N = N
noutput(::MatrixBlock{N}) where N = N

"""
    isunitary(x) -> Bool

Test whether this operator is unitary.
"""
isunitary(op) = op * op' ≈ speye(size(op, 1))

isunitary(x::MatrixBlock) = isunitary(mat(x))
isunitary(::Type{X}) where {X <: MatrixBlock} = isunitary(mat(X))

"""
    ispure(x) -> Bool

Test whether this operator is pure.
"""
ispure(x::MatrixBlock) = true
ispure(::Type{X}) where {X <: MatrixBlock} = true

"""
    isreflexive(x) -> Bool

Test whether this operator is reflexive.
"""
isreflexive(op) = op * op ≈ speye(size(op, 1))

isreflexive(x::MatrixBlock) = isreflexive(mat(x))
isreflexive(::Type{X}) where {X <: MatrixBlock} = isreflexive(mat(X))

"""
    ishermitian(x) -> Bool

Test whether this operator is hermitian.
"""
ishermitian(x::MatrixBlock) = check_hermitian(mat(x))
ishermitian(::Type{X}) where {X <: MatrixBlock} = check_hermitian(mat(X))

check_hermitian(op) = op' ≈ op

"""
    nparameters(x) -> Integer

Returns the number of parameters of `x`.
"""
nparameters(x::MatrixBlock) = 0
nparameters(::Type{X}) where {X <: MatrixBlock} = 0


import Base: eltype
import Compat.SparseArrays: sparse

datatype(block::MatrixBlock{N, T}) where {N, T} = T
dense(block::MatrixBlock) = Array(mat(block))
sparse(block::MatrixBlock) = sparse(mat(block))

function apply!(reg::Register, b::MatrixBlock)
    reg.state .= sparse(b) * reg
    reg
end

include("Primitive.jl")
include("Composite.jl")
