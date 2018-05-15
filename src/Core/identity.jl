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
import Base: transpose, conj, copy, real, ctranspose, imag, transpose!, transpose
for func in (:conj, :real, :ctranspose, :transpose, :copy)
    @eval ($func)(M::Identity{T}) where T = Identity{T}(M.n)
end
for func in (:ctranspose!, :transpose!)
    @eval ($func)(M::Identity{T}) where T = M
end
imag(M::Identity{T}) where T = Diagonal(zeros(T,M.n))

####### basic mathematic operations ######
import Base: *, /, ==
*(A::Identity{T}, B::Number) where T = Diagonal(fill(promote_type(T, eltype(B))(B), A.n))
*(B::Number, A::Identity{T}) where T = Diagonal(fill(promote_type(T, eltype(B))(B), A.n))
/(A::Identity{T}, B::Number) where T = Diagonal(fill(promote_type(T, eltype(B))(1/B), A.n))
==(A::Identity, B::Identity) = A.n == B.n

####### sparse matrix ######
import Base: nnz, nonzeros, inv
nnz(M::Identity) = M.n
nonzeros(M::Identity{T}) where T = ones(T, M.n)

####### linear algebra  ######
inv(M::Identity) = M
det(M::Identity) = 1
logdet(M::Identity) = 0

####### multiply ###########
Mats = Union{SparseMatrixCSC, StridedVecOrMat}
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

function (*)(A::Identity, B::Diagonal)
    size(A, 2) == size(B, 1) || throw(DimensionMismatch())
    B
end
function (*)(A::Diagonal, B::Identity)
    size(A, ndims(A)) == size(B, 1) || throw(DimensionMismatch())
    A
end

for func in (:At_mul_B, :At_mul_Bt, :A_mul_Bt, :Ac_mul_B, :A_mul_Bc, :Ac_mul_Bc)
    @eval begin
        import Base: $func
        @generated ($func)(args...) = (:*)(args...)
        #($func)(args...) = (*)(args...)
    end
end

#TODO
# since 0.7 transpose is different, we don't take transpose serious here.

####### kronecker product ###########
import Base: kron

kron(A::Identity{Ta}, B::Identity{Tb}) where {Ta, Tb}= Identity{promote_type(Ta, Tb)}(A.n*B.n)
kron(A::Identity, B::Diagonal{Tb}) where Tb = Diagonal{Tb}(repeat(B.diag, outer=A.n))
kron(B::Diagonal{Tb}, A::Identity) where Tb = Diagonal{Tb}(repeat(B.diag, inner=A.n))

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
    colptr = prepend!(cumsum(repeat(nl, inner=nB))+1, 1)
    SparseMatrixCSC(mA*nB, nA*nB, colptr, rowval, nzval)
end

######## plus minus diagonal matrix ########

####### tags #########
import Base: ishermitian
ishermitian(D::Identity) = true


####### diagonal kron ########
kron(A::Diagonal, B::Diagonal) = Diagonal(kron(A.diag, B.diag))

function kron(A::StridedMatrix{Tv}, B::Diagonal{Tb}) where {Tv, Tb}
    mA, nA = size(A)
    nB = size(B, 1)
    C = zeros(promote_type(Tv, Tb), mA*nB, nA*nB)
    @inbounds for j = 1:nA
        for i = 1:mA
            val = A[i,j]
            @inbounds @simd for k = 1:nB
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
    @inbounds @simd for i = 1:nA
        C[(i-1)*mB+1:i*mB, (i-1)*nB+1:i*nB] = B*A.diag[i]
    end
    C
end

function kron(A::Diagonal, B::SparseMatrixCSC)
    nA = size(A, 1)
    mB, nB = size(B)
    nV = nnz(B)
    nzval = vcat([B.nzval*A.diag[i] for i in 1:nA]...)
    rowval = vcat([B.rowval+(i-1)*mB for i in 1:nA]...)
    colptr = vcat([B.colptr[(i==1?1:2):end]+(i-1)*nV for i in 1:nA]...)
    SparseMatrixCSC(mB*nA, nB*nA, colptr, rowval, nzval)
end

function kron(A::SparseMatrixCSC{T}, B::Diagonal{Tb}) where {T, Tb}
    nB = size(B, 1)
    mA, nA = size(A)
    nV = nnz(A)
    rowval = Vector{Int}(nB*nV)
    nzval = Vector{promote_type(T, Tb)}(nB*nV)
    z=0
    @inbounds for i in 1:nA
        rstart = A.colptr[i]
        rend = A.colptr[i+1]-1
        row = A.rowval[rstart:rend]
        nzv = A.nzval[rstart:rend]
        nrow = length(row)
        @inbounds @simd for k in 1:nB
            rowval[z+1:z+nrow] = (row-1)*nB+k
            nzval[z+1:z+nrow] = nzv*B.diag[k]
            z+=nrow
        end
    end
    nl = diff(A.colptr)
    colptr = prepend!(cumsum(repeat(nl, inner=nB))+1, 1)
    SparseMatrixCSC(mA*nB, nA*nB, colptr, rowval, nzval)
end
######## plus minus diagonal matrix ########

####### tags #########
import Base: ishermitian
ishermitian(D::Identity) = true
