export MatrixBlock

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
nqubits(::MatrixBlock{N}) where N = N

# NOTE: move to Intrinsics?
isunitary(op) = op * op' ≈ IMatrix(size(op, 1))
isunitary(x::MatrixBlock) = isunitary(mat(x))
isunitary(::Type{X}) where {X <: MatrixBlock} = isunitary(mat(X))

"""
    ispure(x) -> Bool

Test whether this operator is pure.
"""
ispure(x::MatrixBlock) = true
ispure(::Type{X}) where {X <: MatrixBlock} = true

isreflexive(op) = op * op ≈ IMatrix(size(op, 1))
isreflexive(x::MatrixBlock) = isreflexive(mat(x))
isreflexive(::Type{X}) where {X <: MatrixBlock} = isreflexive(mat(X))

"""
    ishermitian(x) -> Bool

Test whether this operator is hermitian.
"""
ishermitian(x::MatrixBlock) = check_hermitian(mat(x))
ishermitian(::Type{X}) where {X <: MatrixBlock} = check_hermitian(mat(X))

check_hermitian(op) = op' ≈ op

nparameters(x::MatrixBlock) = 0
nparameters(::Type{X}) where {X <: MatrixBlock} = 0

datatype(block::MatrixBlock{N, T}) where {N, T} = T

function matrix_type end

function apply!(reg::AbstractRegister, b::MatrixBlock)
    reg.state .= mat(b) * reg
    reg
end

include("BlockCache.jl")
include("Primitive.jl")
include("Composite.jl")
