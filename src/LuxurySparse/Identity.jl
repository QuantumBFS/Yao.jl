import Base: getindex, size, println

"""
    Identity{N, Tv}()
    Identity{N}() where N = Identity{N, Int64}()
    Identity(A::AbstractMatrix{T}) where T -> Identity

Identity matrix, with size N as label, use `Int64` as its default type, both `*` and `kron` are optimized.
"""
struct Identity{N, Tv} <: AbstractMatrix{Tv} end
Identity{N}() where N = Identity{N, Int64}()
Identity(A::AbstractMatrix{T}) where T = Identity{size(A, 1) == size(A,2) ? size(A, 2) : throw(DimensionMismatch()), T}()

size(A::Identity{N}, i::Int) where N = N
size(A::Identity{N}) where N = (N, N)
getindex(A::Identity{N, T}, i::Integer, j::Integer) where {N, T} = T(i==j)

####### transformation #######

### TODO: to static N
import Base: sparse, full
sparse(A::Identity{N, T}) where {N, T} = speye(T, N)
full(A::Identity{N, T}) where {N, T} = eye(T, N)

import Base: convert
convert(::Type{Identity{N, T}}, B::Identity) where {N, T} = Identity{N, T}()

####### basic operations #######
import Base: transpose, conj, copy, real, ctranspose, imag, transpose!, transpose, ctranspose!
for func in (:conj, :real, :ctranspose, :transpose, :copy)
    @eval ($func)(M::Identity{N, T}) where {N, T} = Identity{N, T}()
end
for func in (:ctranspose!, :transpose!)
    @eval ($func)(M::Identity) = M
end
imag(M::Identity{N, T}) where {N, T} = Diagonal(zeros(T,N))

####### basic mathematic operations ######
import Base: *, /, ==, +, -, ≈
*(A::Identity{N, T}, B::Number) where {N, T} = Diagonal(fill(promote_type(T, eltype(B))(B), N))
*(B::Number, A::Identity{N, T}) where {N, T} = Diagonal(fill(promote_type(T, eltype(B))(B), N))
/(A::Identity{N, T}, B::Number) where {N, T} = Diagonal(fill(promote_type(T, eltype(B))(1/B), N))

const IDP = Union{Diagonal, PermMatrix, Identity}
for op in [:+, :-, :(==), :≈]

    @eval begin
        $op(A::IDP, B::SparseMatrixCSC) = $op(sparse(A), B)
        $op(B::SparseMatrixCSC, A::IDP) = $op(B, sparse(A))

        # intra-IDP
        $op(A::PermMatrix, B::IDP) = $op(sparse(A), sparse(B))
        $op(A::IDP, B::PermMatrix) = $op(sparse(A), sparse(B))
        $op(A::PermMatrix, B::PermMatrix) = $op(sparse(A), sparse(B))
    end

    # intra-ID
    if op in [:+, :-]
        @eval begin
            $op(d1::Diagonal, d2::Identity) = Diagonal($op(d1.diag, diag(d2)))
            $op(d1::Identity, d2::Diagonal) = Diagonal($op(diag(d1), d2.diag))
        end
    else
        @eval begin
            $op(d1::Identity, d2::Diagonal) = $op(diag(d1), d2.diag)
            $op(d1::Diagonal, d2::Identity) = $op(d1.diag, diag(d2))
            $op(d1::Identity{Na}, d2::Identity{Nb}) where {Na, Nb} = $op(Na, Nb)
        end
    end

end
+(d1::Identity{Na, Ta}, d2::Identity{Nb, Tb}) where {Na, Nb, Ta, Tb} = d1==d2 ? Diagonal(fill(promote_types(Ta, Tb)(2), Na)) : throw(DimensionMismatch())
-(d1::Identity{Na, Ta}, d2::Identity{Nb, Tb}) where {Na, Ta, Nb, Tb} = d1==d2 ? spzeros(promote_types(Ta, Tb), Na, Na) : throw(DimensionMismatch())

####### sparse matrix ######
import Base: nnz, nonzeros, inv, det, diag, logdet
nnz(M::Identity{N}) where N = N
nonzeros(M::Identity{N, T}) where {N, T} = ones(T, N)

####### linear algebra  ######
inv(M::Identity) = M
det(M::Identity) = 1
diag(M::Identity{N, T}) where {N, T} = ones{T}(N)
logdet(M::Identity) = 0

####### multiply ###########
for T in [:AbstractVecOrMat, :SparseMatrixCSC, :PermMatrix, :Diagonal, :StridedMatrix]
    @eval (*)(A::Identity, B::$T) = size(A, 2) == size(B, 1) ? B : throw(DimensionMismatch())
    @eval (*)(A::$T, B::Identity) = size(A, ndims(A)) == size(B, 1) ? A : throw(DimensionMismatch())
end
(*)(A::Identity, B::Identity) = size(A, 2) == size(B, 1) ? A : throw(DimensionMismatch())

#TODO
# since 0.7 transpose is different, we don't take transpose serious here.

####### kronecker product ###########
import Base: kron
#TODO if Identity{1}, do nothing
kron(A::Identity{Na, Ta}, B::Identity{Nb, Tb}) where {Na, Nb, Ta, Tb}= Identity{Na*Nb, promote_type(Ta, Tb)}()
kron(A::Identity{Na}, B::Diagonal) where Na = Diagonal(orepeat(B.diag, Na))
kron(B::Diagonal, A::Identity{Na}) where Na = Diagonal(irepeat(B.diag, Na))
for MAT in [:Diagonal, :SparseMatrixCSC, :PermMatrix, :StridedMatrix]
    @eval kron(A::Identity{1}, B::$MAT) = B
    @eval kron(B::$MAT, A::Identity{1}) = B
end

function kron(A::AbstractMatrix{Tv}, B::Identity{Nb}) where {Nb, Tv}
    mA, nA = size(A)
    nzval = Vector{Tv}(Nb*mA*nA)
    rowval = Vector{Int}(Nb*mA*nA)
    colptr = collect(1:mA:Nb*mA*nA+1)
    @inbounds for j = 1:nA
        source = A[:,j]
        startbase = (j-1)*Nb*mA - mA
        @inbounds for j2 = 1:Nb
            start = startbase + j2*mA
            row = j2-Nb
            @inbounds @simd for i = 1:mA
                nzval[start+i] = source[i]
                rowval[start+i] = row+Nb*i
            end
        end
    end
    SparseMatrixCSC(mA*Nb, nA*Nb, colptr, rowval, nzval)
end

function kron(A::Identity{Na}, B::AbstractMatrix{Tv}) where {Na, Tv}
    mB, nB = size(B)
    rowval = Vector{Int}(nB*mB*Na)
    nzval = Vector{Tv}(nB*mB*Na)
    @inbounds for j in 1:Na
        r0 = (j-1)*mB
        @inbounds for j2 in 1:nB
            start = ((j-1)*nB+j2-1)*mB
            @inbounds @simd for i in 1:mB
                rowval[start+i] = r0+i
                nzval[start+i] = B[i,j2]
            end
        end
    end
    colptr = collect(1:mB:nB*mB*Na+1)
    SparseMatrixCSC(mB*Na, Na*nB, colptr, rowval, nzval)
end

function kron(A::Identity{Na}, B::SparseMatrixCSC{T}) where {Na, T}
    mB, nB = size(B)
    nV = nnz(B)
    nzval = Vector{T}(Na*nV)
    rowval = Vector{Int}(Na*nV)
    colptr = Vector{Int}(nB*Na+1)
    nzval = Vector{T}(Na*nV)
    colptr[1] = 1
    @inbounds for i = 1:Na
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
    SparseMatrixCSC(mB*Na, nB*Na, colptr, rowval, nzval)
end

function kron(A::SparseMatrixCSC{T}, B::Identity{Nb}) where {T, Nb}
    mA, nA = size(A)
    nV = nnz(A)
    rowval = Vector{Int}(Nb*nV)
    colptr = Vector{Int}(nA*Nb+1)
    nzval = Vector{T}(Nb*nV)
    z=1
    colptr[1] = 1
    @inbounds for i in 1:nA
        rstart = A.colptr[i]
        rend = A.colptr[i+1]-1
        colbase = (i-1)*Nb+1
        @inbounds for k in 1:Nb
            irow_Nb = k - Nb
            @inbounds @simd for r in rstart:rend
                rowval[z] = A.rowval[r]*Nb+irow_Nb
                nzval[z] = A.nzval[r]
                z+=1
            end
            colptr[colbase+k] = z
        end
    end
    SparseMatrixCSC(mA*Nb, nA*Nb, colptr, rowval, nzval)
end

function kron(A::PermMatrix{T}, B::Identity) where T
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
    PermMatrix(perm, vals)
end

function kron(A::Identity, B::PermMatrix{T}) where T
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
    PermMatrix(perm, vals)
end

####### tags #########
import Base: ishermitian
ishermitian(D::Identity) = true
I(n::Int) = Identity{n}()

import Base: eye
eye(A::PermMatrix{Tv}) where Tv = Identity{size(A, 1) == size(A,2) ? size(A, 2) : throw(DimensionMismatch()), Tv}()
