using YaoBase, YaoArrayRegister
export GeneralMatrixGate, matgate

"""
    GeneralMatrixGate{M, N, T, MT} <: PrimitiveBlock{N, T}

General matrix gate wraps a matrix operator to quantum gates. This is the most
general form of a quantum gate. `M` is the hilbert dimension (first dimension),
`N` is the hilbert dimension (second dimension) of current quantum state. For
most quantum gates, we have ``M = N``.
"""
struct GeneralMatrixGate{M, N, T, MT <: AbstractMatrix{T}} <: PrimitiveBlock{N, T}
    mat::MT

    function GeneralMatrixGate{M, N}(m::MT) where {M, N, T, MT <: AbstractMatrix{T}}
        (1 << M, 1 << N) == size(m) ||
            throw(DimensionMismatch("expect a $(1<<M) x $(1<<N) matrix, got $(size(m))"))

        return new{M, N, T, MT}(m)
    end
end

GeneralMatrixGate(m::AbstractMatrix) = GeneralMatrixGate{log2i.(size(m))...}(m)

"""
    matgate(m::AbstractMatrix)

Create a [`GeneralMatrixGate`](@ref) with a matrix `m`.
"""
matgate(m::AbstractMatrix) = GeneralMatrixGate(m)

"""
    matgate(m::AbstractMatrix)

Create a [`GeneralMatrixGate`](@ref) with a matrix `m`.
"""
matgate(m::AbstractBlock) = GeneralMatrixGate(mat(m))

mat(A::GeneralMatrixGate) = A.mat

Base.:(==)(A::GeneralMatrixGate, B::GeneralMatrixGate) = A.mat == B.mat
Base.copy(A::GeneralMatrixGate) = GeneralMatrixGate(copy(A.mat))
