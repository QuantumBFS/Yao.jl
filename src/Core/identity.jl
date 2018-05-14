import Base: getindex, size, println
struct Identity{Tv} <: AbstractMatrix{Tv}
    n::Int
end
Identity(n::Int) = Identity{Int}(n)

size(A::Identity, i::Int) = A.n
size(A::Identity) = (A.n, A.n)
getindex(A::Identity{T}, i::Integer, j::Integer) where T = T(i==j)

####### transformation #######
import Base: sparse, full
sparse(A::Identity{T}) where T = speye(T, A.n)
full(A::Identity{T}) where T = eye(T, A.n)

####### basic operations #######
import Base: transpose, conj, copy, real, imag, ctranspose
for func in (:conj, :real, :imag, :ctranspose, :transpose, :copy)
    @eval ($func)(M::Identity{T}) where T = Identity{T}(M.n)
end

####### basic mathematic operations ######
import Base: *, /, ==
*(A::Identity{T}, B::Number) where T = Diagonal(fill(promote_type(T, eltype(B))(B), A.n))
*(B::Number, A::Identity{T}) where T = Diagonal(fill(promote_type(T, eltype(B))(B), A.n))
/(A::Identity{T}, B::Number) where T = Diagonal(fill(promote_type(T, eltype(B))(1/B), A.n))
==(A::Identity, B::Identity) = A.n == B.n

####### sparse matrix and linear algebra ######
import Base: nnz, nonzeros, inv
nnz(M::Identity) = M.n
nonzeros(M::Identity{T}) where T = ones(T, M.n)
inv(M::Identity) = M

####### multiply ###########
Mats = Union{SparseMatrixCSC, StridedVecOrMat, Diagonal}
function (*)(A::Identity, B::Mats)
    size(A, 2) == size(B, 1) || throw(DimensionMismatch())
    B
end
function (*)(A::Mats, B::Identity)
    size(A, ndims(A)) == size(B, 1) || throw(DimensionMismatch())
    A
end
function (*)(A::Identity, B::Identity)
    size(A, 2) == size(B, 1) || throw(DimensionMismatch())
    B
end

####### kronecker product ###########
import Base: kron

kron(A::Identity{Ta}, B::Identity{Tb}) where {Ta, Tb}= Identity{promote_type(Ta, Tb)}(A.n*B.n)n+1

function kron(A::StridedMatrix{Tv}, B::Identity) where Tv
    mA, nA = size(A)
    nB = B.n
    C = zeros(Tv, mA*nB, nA*nB)
    @inbounds for j = 1:nA
        for i = 1:mA
            val = A[i,j]
            @inbounds @simd for k = 1:nB
                C[(i-1)*nB+k, (j-1)*nB+k] = val
            end
        end
    end
    C
end

function kron(A::Identity, B::StridedMatrix{Tv}) where Tv
    mB, nB = size(B)
    nA = A.n
    C = zeros(Tv, mB*nA, nB*nA)
    @inbounds @simd for i = 1:nA
        C[(i-1)*mB+1:i*mB, (i-1)*nB+1:i*nB] = B
    end
    C
end

function kron(A::Identity, B::SparseMatrixCSC)
    nA = A.n
    mB, nB = size(B)
    nV = nnz(B)
    nzval = repeat(B.nzval, outer=nA)
    rowval = vcat([B.rowval+(i-1)*mB for i in 1:nA]...)
    colptr = vcat([B.colptr[(i==1?1:2):end]+(i-1)*nV for i in 1:nA]...)
    SparseMatrixCSC(mB*nA, nB*nA, colptr, rowval, nzval)
end

function kron(A::SparseMatrixCSC{T}, B::Identity) where T
    nB = B.n
    mA, nA = size(A)
    nV = nnz(A)
    rowval = Vector{Int}(nB*nV)
    nzval = Vector{T}(nB*nV)
    z=0
    @inbounds for i in 1:nA
        rstart = A.colptr[i]
        rend = A.colptr[i+1]-1
        row = A.rowval[rstart:rend]
        nzv = A.nzval[rstart:rend]
        nrow = length(row)
        @inbounds @simd for k in 1:nB
            rowval[z+1:z+nrow] = (row-1)*nB+k
            nzval[z+1:z+nrow] = nzv
            z+=nrow
        end
    end
    nl = diff(A.colptr)
    colptr = prepend!(cumsum(repeat(nl, inner=nA))+1, 1)
    SparseMatrixCSC(mA*nB, nA*nB, colptr, rowval, nzval)
end
