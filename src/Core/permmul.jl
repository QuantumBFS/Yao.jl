"""
Multiply and permute sparse matrix
"""

struct PermuteMultiply{Tv, Ti<:Integer} <: AbstractMatrix{Tv}
    perm::Vector{Ti}   # new orders
    vals::Vector{Tv}  # multiplied values.

    function PermuteMultiply{Tv, Ti}(perm::Vector{Ti}, vals::Vector{Tv}) where {Tv, Ti<:Integer}
        if length(perm) != length(vals)
            throw(DimensionMismatch("permutation ($(length(perm))) and multiply ($(length(vals))) length mismatch."))
        end
        new{Tv, Ti}(perm, vals)
    end
end

function PermuteMultiply(perm::Vector, vals::Vector)
    Tv = eltype(vals)
    Ti = eltype(perm)
    PermuteMultiply{Tv,Ti}(perm, vals)
end

PermuteMultiply(dmat::Diagonal) = PermuteMultiply(collect(1:size(dmat, 1)), dmat.diag)

################# Matrix Inherence ##################
# size, getindex 
import Base: size, getindex, sparse, full
size(M::PermuteMultiply) = (length(M.perm), length(M.perm))
function size(A::PermuteMultiply, d::Integer)
    if d < 1
        throw(ArgumentError("dimension must be ≥ 1, got $d"))
    elseif d<=2
        return length(A.perm)
    else
        return 1
    end
end
getindex(M::PermuteMultiply, i::Integer, j::Integer) = M.perm[i] == j ? M.vals[i] : 0

################ speed up conversion to: matrix/array/sparse/show  ############
function Matrix{T}(M::PermuteMultiply) where T
    n = size(M, 1)
    Mf = zeros(T, n, n)
    @inbounds for i=1:n
        Mf[i, M.perm[i]] = M.vals[i]
    end
    return Mf
end
Matrix(M::PermuteMultiply{T}) where {T} = Matrix{T}(M)
Array(M::PermuteMultiply) = Matrix(M)
full(M::PermuteMultiply) = Matrix(M)

function sparse(M::PermuteMultiply{T}) where {T}
    n = size(M, 1)
    sparse(collect(1:n), M.perm, M.vals, n, n)
end

function show(io::IO, M::PermuteMultiply)
    println("PermuteMultiply")
    for item in zip(M.perm, M.vals)
        i, p = item
        println("- ($i) * $p")
    end
end


######## Elementary operations ########
import Base: copy, transpose, conj, real, imag
for func in (:conj, :real, :imag)
    @eval ($func)(M::PermuteMultiply) = PermuteMultiply(M.perm, ($func)(M.vals))
end
copy(M::PermuteMultiply) = PermuteMultiply(copy(M.perm), copy(M.vals))

function transpose(M::PermuteMultiply)
    new_perm = sortperm(M.perm)
    return PermuteMultiply(new_perm, M.vals[new_perm])
end

adjoint(S::PermuteMultiply{<:Real}) = transpose(S)
adjoint(S::PermuteMultiply{<:Complex}) = conj(transpose(S))


######### Mathematical ###############
import Base: *, /, ==
*(A::PermuteMultiply, B::Number) = PermuteMultiply(A.perm, A.vals*B)
*(B::Number, A::PermuteMultiply) = A*B
/(A::PermuteMultiply, B::Number) = PermuteMultiply(A.perm, A.vals/B)
==(A::PermuteMultiply, B::PermuteMultiply) = (A.perm==B.perm) && (A.vals==B.vals)

#+(A::PermuteMultiply, B::PermuteMultiply) = PermuteMultiply(A.dv+B.dv, A.ev+B.ev)
#-(A::PermuteMultiply, B::PermuteMultiply) = PermuteMultiply(A.dv-B.dv, A.ev-B.ev)

######### sparse array interfaces  #########
import Base: nnz, nonzeros, inv
nnz(M::PermuteMultiply) = length(M.vals)
nonzeros(M::PermuteMultiply) = M.vals

function inv(M::PermuteMultiply)
    new_perm = sortperm(M.perm)
    return PermuteMultiply(new_perm, 1.0./M.vals[new_perm])
end

########## Multiplication ############# making them dry?
function (*)(A::PermuteMultiply, X::AbstractVector)
    length(X) == size(A, 2) || throw(DimensionMismatch())
    return A.vals .* X[A.perm]
end

function (*)(A::PermuteMultiply, B::PermuteMultiply)
    size(A, 1) == size(B, 1) || throw(DimensionMismatch())
    PermuteMultiply(B.perm[A.perm], A.vals.*B.vals[A.perm])
end


function (*)(X::AbstractVector, A::PermuteMultiply)
    length(X) == size(A, 1) || throw(DimensionMismatch())
    return (A.vals .* X)[sortperm(A.perm)]
end

function (*)(A::PermuteMultiply, X::AbstractMatrix)
    size(X, 1) == size(A, 2) || throw(DimensionMismatch())
    return A.vals .* X[A.perm, :]   # this may be inefficient for sparse CSC matrix.
end

function (*)(X::AbstractMatrix, A::PermuteMultiply)
    size(X, 2) == size(A, 1) || throw(DimensionMismatch())
    return (A.vals' .* X)[:, sortperm(A.perm)] # how can we lazy evaluate and cache this sort order?
end
function (*)(D::Diagonal, A::PermuteMultiply)
    vals = A.vals.*D.diag
    return PermuteMultiply(A.perm, vals)
end

function (*)(A::PermuteMultiply, D::Diagonal)
    vals = A.vals.*D.diag[A.perm]
    return PermuteMultiply(A.perm, vals)
end

############### kron ######################
import Base: kron
function kron(A::StridedMatrix{Tv}, B::PermuteMultiply{Tb}) where {Tv, Tb}
    mA, nA = size(A)
    nB = size(B, 1)
    C = zeros(promote_type(Tv, Tb), mA*nB, nA*nB)
    @inbounds for j = 1:nA
        for i = 1:mA
            val = A[i,j]
            @simd for k = 1:nB
                C[(i-1)*nB+k, (j-1)*nB+k] = val*B.diag[k]  # merge
            end
        end
    end
    C
end

function kron(A::PermuteMultiply{Ta}, B::StridedMatrix{Tv}) where {Tv, Ta}
    mB, nB = size(B)
    nA = size(A, 1)
    C = zeros(promote_type(Tv, Ta), mB*nA, nB*nA)
    @simd for i = 1:nA
        @inbounds C[(i-1)*mB+1:i*mB, (i-1)*nB+1:i*nB] = B*A.diag[i]  #!!!!!!
    end
    C
end

function kron(A::PermuteMultiply{Ta}, B::PermuteMultiply{Tb}) where {Ta, Tb}
    nA = size(A, 1)
    nB = size(B, 1)
    Tc = promote_type(Ta, Tb)
    vals = kron(A.vals, B.vals)
    perm = Vector{Int}(nB*nA)
    @inbounds for i = 1:nA
        perm[(i-1)*nB+1:i*nB] = (A.perm[i]-1)*nB +B.perm
    end
    PermuteMultiply(perm, vals)
end

kron(A::PermuteMultiply, B::Diagonal) = kron(A, PermuteMultiply(B))
kron(A::Diagonal, B::PermuteMultiply) = kron(PermuteMultiply(A), B)

function kron(A::PermuteMultiply{Ta}, B::SparseMatrixCSC{Tb}) where {Ta, Tb}
    nA = size(A, 1)
    mB, nB = size(B)
    nV = nnz(B)
    perm = sortperm(A.perm)
    nzval = Vector{promote_type(Ta, Tb)}(nA*nV)
    rowval = Vector{Int}(nA*nV)
    colptr = Vector{Int}(nA*nB+1)
    colptr[1] = 1
    @inbounds for i in 1:nA
        start_row = (i-1)*nV
        start_ri = (perm[i]-1)*mB
        v0 = A.vals[perm[i]]
        @simd for j = 1:nV
            nzval[start_row+j] = B.nzval[j]*v0
            rowval[start_row+j] = B.rowval[j] + start_ri
        end
        start_col = (i-1)*nB+1
        start_ci = (i-1)*nV
        @simd for j = 1:nB
            colptr[start_col+j] = B.colptr[j+1] + start_ci
        end
    end
    SparseMatrixCSC(mB*nA, nB*nA, colptr, rowval, nzval)
end

function kron(A::SparseMatrixCSC{T}, B::PermuteMultiply{Tb}) where {T, Tb}
    nB = size(B, 1)
    mA, nA = size(A)
    nV = nnz(A)
    perm = sortperm(B.perm)
    rowval = Vector{Int}(nB*nV)
    colptr = Vector{Int}(nA*nB+1)
    nzval = Vector{promote_type(T, Tb)}(nB*nV)
    z=1
    colptr[z] = 1
    @inbounds for i in 1:nA
        rstart = A.colptr[i]
        rend = A.colptr[i+1]-1
        @simd for k in 1:nB
            irow = perm[k]
            for r in rstart:rend
                rowval[z] = (A.rowval[r]-1)*nB+irow
                nzval[z] = A.nzval[r]*B.vals[irow]
                z+=1
            end
            colptr[(i-1)*nB+k+1] = z
        end
    end
    SparseMatrixCSC(mA*nB, nA*nB, colptr, rowval, nzval)
end

####### diagonal kron ########
kron(A::Diagonal, B::Diagonal) = Diagonal(kron(A.diag, B.diag))

function kron(A::StridedMatrix{Tv}, B::Diagonal{Tb}) where {Tv, Tb}
    mA, nA = size(A)
    nB = size(B, 1)
    C = zeros(promote_type(Tv, Tb), mA*nB, nA*nB)
    @inbounds for j = 1:nA
        for i = 1:mA
            val = A[i,j]
            @simd for k = 1:nB
                C[(i-1)*nB+k, (j-1)*nB+k] = val*B.diag[k]  # merge
            end
        end
    end
    C
end

function kron(A::Diagonal{Ta}, B::StridedMatrix{Tv}) where {Tv, Ta}
    mB, nB = size(B)
    nA = size(A, 1)
    C = zeros(promote_type(Tv, Ta), mB*nA, nB*nA)
    @simd for i = 1:nA
        @inbounds C[(i-1)*mB+1:i*mB, (i-1)*nB+1:i*nB] = B*A.diag[i]  #!!!!!!
    end
    C
end

kron(A::Diagonal, B::SparseMatrixCSC) = kron(PermuteMultiply(A), B)
kron(A::SparseMatrixCSC, B::Diagonal) = kron(A, PermuteMultiply(B))
