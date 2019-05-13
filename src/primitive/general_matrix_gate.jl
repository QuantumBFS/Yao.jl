using YaoBase, YaoArrayRegister
export GeneralMatrixBlock, matblock

"""
    GeneralMatrixBlock{M, N, MT} <: PrimitiveBlock{N}

General matrix gate wraps a matrix operator to quantum gates. This is the most
general form of a quantum gate. `M` is the hilbert dimension (first dimension),
`N` is the hilbert dimension (second dimension) of current quantum state. For
most quantum gates, we have ``M = N``.
"""
struct GeneralMatrixBlock{M, N, T, MT <: AbstractMatrix{T}} <: PrimitiveBlock{N}
    mat::MT

    function GeneralMatrixBlock{M, N}(m::MT) where {M, N, T, MT <: AbstractMatrix{T}}
        (1 << M, 1 << N) == size(m) ||
            throw(DimensionMismatch("expect a $(1<<M) x $(1<<N) matrix, got $(size(m))"))

        return new{M, N, T, MT}(m)
    end
end

GeneralMatrixBlock(m::AbstractMatrix) = GeneralMatrixBlock{log2i.(size(m))...}(m)

"""
    matblock(m::AbstractMatrix)

Create a [`GeneralMatrixBlock`](@ref) with a matrix `m`.

# Example

```jldoctest
julia> matblock(ComplexF64[0 1;1 0])
matblock(...)
```
"""
matblock(m::AbstractMatrix) = GeneralMatrixBlock(m)

"""
    matblock(m::AbstractMatrix)

Create a [`GeneralMatrixBlock`](@ref) with a matrix `m`.
"""
matblock(m::AbstractBlock) = GeneralMatrixBlock(mat(m))

function mat(::Type{T}, A::GeneralMatrixBlock) where T
    if eltype(A.mat) == T
        return A.mat
    else
        # this errors before, but since we allow one to specify T in mat
        # this should be allowed but with a suggestion
        @warn "converting $(eltype(A.mat)) to eltype $T, consider create another matblock with eltype $T"
        return copyto!(similar(A.mat, T), A.mat)
    end
end

Base.:(==)(A::GeneralMatrixBlock, B::GeneralMatrixBlock) = A.mat == B.mat
Base.copy(A::GeneralMatrixBlock) = GeneralMatrixBlock(copy(A.mat))
