include("permmul.jl")
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
diag(M::Identity{T}) where T = ones{T}(M.n)
logdet(M::Identity) = 0

####### multiply ###########
for T in [:AbstractVecOrMat, :SparseMatrixCSC, :PermuteMultiply, :Diagonal, :StridedMatrix]
    @eval (*)(A::Identity, B::$T) = size(A, 2) == size(B, 1)?B:throw(DimensionMismatch())
    @eval (*)(A::$T, B::Identity) = size(A, ndims(A)) == size(B, 1)?A:throw(DimensionMismatch())
end
(*)(A::Identity, B::Identity) = size(A, 2) == size(B, 1)?A:throw(DimensionMismatch())

#for func in (:At_mul_B, :At_mul_Bt, :A_mul_Bt, :Ac_mul_B, :A_mul_Bc, :Ac_mul_Bc)
#    @eval begin
#        import Base: $func
#        @generated ($func)(args...) = (:*)(args...)
#    end
#end

#TODO
# since 0.7 transpose is different, we don't take transpose serious here.

####### kronecker product ###########
import Base: kron

kron(A::Identity{Ta}, B::Identity{Tb}) where {Ta, Tb}= Identity{promote_type(Ta, Tb)}(A.n*B.n)
kron(A::Identity, B::Diagonal) = Diagonal(orepeat(B.diag, A.n))
kron(B::Diagonal, A::Identity) = Diagonal(irepeat(B.diag, A.n))

function kron(A::AbstractMatrix{Tv}, B::Identity) where Tv
    mA, nA = size(A)
    nB = B.n
    nzval = Vector{Tv}(nB*mA*nA)
    rowval = Vector{Int}(nB*mA*nA)
    colptr = collect(1:mA:nB*mA*nA+1)
    @inbounds for j = 1:nA
        source = A[:,j]
        startbase = (j-1)*nB*mA - mA
        @inbounds for j2 = 1:nB
            start = startbase + j2*mA
            row = j2-nB
            @inbounds @simd for i = 1:mA
                nzval[start+i] = source[i]
                rowval[start+i] = row+nB*i
            end
        end
    end
    SparseMatrixCSC(mA*nB, nA*nB, colptr, rowval, nzval)
end

function kron(A::Identity, B::AbstractMatrix{Tv}) where Tv
    nA = A.n
    mB, nB = size(B)
    rowval = Vector{Int}(nB*mB*nA)
    nzval = Vector{Tv}(nB*mB*nA)
    @inbounds for j in 1:nA
        r0 = (j-1)*mB
        @inbounds for j2 in 1:nB
            start = ((j-1)*nB+j2-1)*mB
            @inbounds @simd for i in 1:mB
                rowval[start+i] = r0+i
                nzval[start+i] = B[i,j2]
            end
        end
    end
    colptr = collect(1:mB:nB*mB*nA+1)
    SparseMatrixCSC(mB*nA, nA*nB, colptr, rowval, nzval)
end

function kron(A::Identity, B::SparseMatrixCSC{T}) where T
    nA = A.n
    mB, nB = size(B)
    nV = nnz(B)
    nzval = Vector{T}(nA*nV)
    rowval = Vector{Int}(nA*nV)
    colptr = Vector{Int}(nB*nA+1)
    nzval = Vector{T}(nA*nV)
    colptr[1] = 1
    @inbounds for i = 1:nA
        r0 = (i-1)*mB
        start = nV*(i-1)
        @inbounds @simd for k = 1:nV
            rowval[start+k] = B.rowval[k]+r0
            nzval[start+k] = B.nzval[k]
        end
        colbase = (i-1)*nB
        @inbounds @simd for j=2:nB+1
            colptr[colbase+j] = B.colptr[j]+start
        end
    end
    SparseMatrixCSC(mB*nA, nB*nA, colptr, rowval, nzval)
end

function kron(A::SparseMatrixCSC{T}, B::Identity) where T
    nB = B.n
    mA, nA = size(A)
    nV = nnz(A)
    rowval = Vector{Int}(nB*nV)
    colptr = Vector{Int}(nA*nB+1)
    nzval = Vector{T}(nB*nV)
    z=1
    colptr[1] = 1
    @inbounds for i in 1:nA
        rstart = A.colptr[i]
        rend = A.colptr[i+1]-1
        colbase = (i-1)*nB+1
        @inbounds for k in 1:nB
            irow_nB = k - nB
            @inbounds @simd for r in rstart:rend
                rowval[z] = A.rowval[r]*nB+irow_nB
                nzval[z] = A.nzval[r]
                z+=1
            end
            colptr[colbase+k] = z
        end
    end
    SparseMatrixCSC(mA*nB, nA*nB, colptr, rowval, nzval)
end

function kron(A::PermuteMultiply{T}, B::Identity) where T
    nA = size(A, 1)
    nB = size(B, 1)
    vals = Vector{T}(nB*nA)
    perm = Vector{Int}(nB*nA)
    @inbounds for i = 1:nA
        start = (i-1)*nB
        permAi = (A.perm[i]-1)*nB
        val = A.vals[i]
        @inbounds @simd for j = 1:nB
            perm[start+j] = permAi + j
            vals[start+j] = val
        end
    end
    PermuteMultiply(perm, vals)
end

function kron(A::Identity, B::PermuteMultiply{T}) where T
    nA = size(A, 1)
    nB = size(B, 1)
    perm = Vector{Int}(nB*nA)
    vals = Vector{T}(nB*nA)
    @inbounds for i = 1:nA
        start = (i-1)*nB
        @inbounds @simd for j = 1:nB
            perm[start+j] = start +B.perm[j]
            vals[start+j] = B.vals[j]
        end
    end
    PermuteMultiply(perm, vals)
end
######## plus minus diagonal matrix ########

####### tags #########
import Base: ishermitian
ishermitian(D::Identity) = true
II(n::Int) = Identity(n)
