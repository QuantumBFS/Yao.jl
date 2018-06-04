import Base: inv
import Compat.LinearAlgebra: det, diag, logdet

####### linear algebra  ######
inv(M::IMatrix) = M
det(M::IMatrix) = 1
diag(M::IMatrix{N, T}) where {N, T} = ones(T, N)
logdet(M::IMatrix) = 0

#det(M::PermMatrix) = parity(M.perm)*prod(M.vals)
function inv(M::PermMatrix)
    new_perm = invperm(M.perm)
    return PermMatrix(new_perm, 1.0./M.vals[new_perm])
end

####### multiply ###########
*(A::IMatrix{N}, B::AbstractVector) where N = size(A, 2) == size(B, 1) ? B :
    throw(DimensionMismatch("matrix A has dimensions $(size(A)), matrix B has dimensions $((size(B, 1), 1))"))

for MATTYPE in [:AbstractMatrix, :StridedMatrix, :Diagonal, :SparseMatrixCSC, :Matrix, :PermMatrix]
    @eval *(A::IMatrix{N}, B::$MATTYPE) where N = N == size(B, 1) ? B :
        throw(DimensionMismatch("matrix A has dimensions $(size(A)), matrix B has dimensions $(size(B))"))

        @eval *(A::$MATTYPE, B::IMatrix{N}) where N = size(A, 2) == N ? A :
        throw(DimensionMismatch("matrix A has dimensions $(size(A)), matrix B has dimensions $(size(B))"))
end

# TODO: use Adjoint to fix this in v0.7
*(A::RowVector, B::IMatrix) = size(A, 1) == size(B, 1) ? B :
    throw(DimensionMismatch("matrix A has dimensions $(size(A)), matrix B has dimensions $(size(B))"))

*(A::IMatrix, B::IMatrix) = size(A, 2) == size(B, 1) ? A :
    throw(DimensionMismatch("matrix A has dimensions $(size(A)), matrix B has dimensions $(size(B))"))


########## Multiplication #############

# NOTE: making them dry?
# to vector
function *(A::PermMatrix{Ta}, X::AbstractVector{Tx}) where {Ta, Tx}
    nX = length(X)
    nX == size(A, 2) || throw(DimensionMismatch())
    v = similar(X, promote_type(Ta, Tx))
    @simd for i = 1:nX
        @inbounds v[i] = A.vals[i]*X[A.perm[i]]
    end
    v
end

function *(X::RowVector{Tx}, A::PermMatrix{Ta}) where {Tx, Ta}
    nX = length(X)
    nX == size(A, 1) || throw(DimensionMismatch())
    v = similar(X, promote_type(Tx, Ta))
    @simd for i = 1:nX
        @inbounds v[A.perm[i]] = A.vals[i]*X[i]
    end
    v
end

# to diagonal
function *(D::Diagonal{Td}, A::PermMatrix{Ta}) where {Td, Ta}
    T = Base.promote_op(*, Td, Ta)
    PermMatrix(A.perm, A.vals .* D.diag)
end

function *(A::PermMatrix{Ta}, D::Diagonal{Td}) where {Td, Ta}
    T = Base.promote_op(*, Td, Ta)
    PermMatrix(A.perm, A.vals .* view(D.diag, A.perm))
end

# to self
function *(A::PermMatrix, B::PermMatrix)
    size(A, 1) == size(B, 1) || throw(DimensionMismatch())
    PermMatrix(B.perm[A.perm], A.vals.*view(B.vals, A.perm))
end

# to matrix
function *(A::PermMatrix, X::AbstractMatrix)
    size(X, 1) == size(A, 2) || throw(DimensionMismatch())
    return @views A.vals .* X[A.perm, :]   # this may be inefficient for sparse CSC matrix.
end

function *(X::AbstractMatrix, A::PermMatrix)
    mX, nX = size(X)
    nX == size(A, 1) || throw(DimensionMismatch())
    return @views (A.vals' .* X)[:, invperm(A.perm)]
end

@static if VERSION >= v"0.7-"
# NOTE: this is just a temperory fix for v0.7. We should overload mul! in
# the future (when we start to drop v0.6) to enable buildin lazy evaluation.

for MTYPE in [PermMatrix, IMatrix]

    @eval begin

        function *(lhs::Adjoint{T, <:AbstractArray{T}}, rhs::$MTYPE) where {T <: Real}
            transpose(lhs.parent) * rhs
        end

        function *(lhs::Adjoint{T, <:AbstractArray{T}}, rhs::$MTYPE) where {T <: Complex}
            conj(transpose(lhs.parent)) * rhs
        end

        function *(lhs::Adjoint{T, <:AbstractVector{T}}, rhs::$MTYPE) where {T <: Complex}
            conj(transpose(lhs.parent)) * rhs
        end

        function *(lhs::Adjoint{T, <:AbstractVector{T}}, rhs::$MTYPE) where {T <: Real}
            transpose(lhs.parent) * rhs
        end

        function *(lhs::Transpose{T, <:AbstractArray{T}}, rhs::$MTYPE) where T
            copy(transpose(lhs.parent)) * rhs
        end

        function *(lhs::Transpose{T, <:AbstractVector{T}}, rhs::$MTYPE) where T
            transpose(transpose(rhs) * lhs.parent)
        end

    end

end # ex

end

# to sparse
function *(A::PermMatrix, X::SparseMatrixCSC)
    nA = size(A, 1)
    mX, nX = size(X)
    mX == nA || throw(DimensionMismatch())
    perm = invperm(A.perm)
    nzval = similar(X.nzval)
    rowval = similar(X.rowval)
    @inbounds for j = 1:nA
        @inbounds @simd for k = X.colptr[j]:X.colptr[j+1]-1
            r = perm[X.rowval[k]]
            nzval[k] = X.nzval[k]*A.vals[r]
            rowval[k] = r
        end
    end
    SparseMatrixCSC(mX, nX, X.colptr, rowval, nzval)
end

function *(X::SparseMatrixCSC, A::PermMatrix)
    nA = size(A, 1)
    mX, nX = size(X)
    nX == nA || throw(DimensionMismatch())
    perm = invperm(A.perm)
    nzval = similar(X.nzval)
    colptr = similar(X.colptr)
    rowval = similar(X.rowval)
    colptr[1] = 1
    z = 1
    @inbounds for j = 1:nA
        pk = perm[j]
        va = A.vals[pk]
        @inbounds @simd for k = X.colptr[pk]:X.colptr[pk+1]-1
            nzval[z] = X.nzval[k]*va
            rowval[z] = X.rowval[k]
            z+=1
        end
        colptr[j+1] = z
    end
    SparseMatrixCSC(mX, nX, colptr, rowval, nzval)
end
