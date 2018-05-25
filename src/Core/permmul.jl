include("utils.jl")

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

function PermuteMultiply(ds::AbstractMatrix)
    i,j,v = findnz(ds)
    j == collect(1:size(ds, 2)) || throw(ArgumentError())
    order = invperm(i)
    PermuteMultiply(order, v[order])
end

import Base: convert
convert(::Type{PermuteMultiply{T}}, B::PermuteMultiply) where T = PermuteMultiply(B.perm, T.(B.vals))

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
pmrand(T::Type, n::Int) = PermuteMultiply(randperm(n), randn(T, n))
pmrand(n::Int) = PermuteMultiply(randperm(n), randn(n))

function sparse(M::PermuteMultiply{T}) where {T}
    n = size(M, 1)
    dropzeros(sparse(collect(1:n), M.perm, M.vals, n, n))
end

import Base: show
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
    new_perm = invperm(M.perm)
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
    new_perm = invperm(M.perm)
    return PermuteMultiply(new_perm, 1.0./M.vals[new_perm])
end

########## Multiplication ############# making them dry?
# to vector
function (*)(A::PermuteMultiply{Ta}, X::AbstractVector{Tx}) where {Ta, Tx}
    nX = length(X)
    nX == size(A, 2) || throw(DimensionMismatch())
    v = similar(X, promote_type(Ta, Tx))
    @simd for i = 1:nX
        @inbounds v[i] = A.vals[i]*X[A.perm[i]]
    end
    v
end

function (*)(X::AbstractVector{Tx}, A::PermuteMultiply{Ta}) where {Tx, Ta}
    nX = length(X)
    nX == size(A, 1) || throw(DimensionMismatch())
    v = similar(X, promote_type(Tx, Ta))
    @simd for i = 1:nX
        @inbounds v[A.perm[i]] = A.vals[i]*X[i]
    end
    v
end

# to diagonal
function (*)(D::Diagonal{Td}, A::PermuteMultiply{Ta}) where {Td, Ta}
    T = Base.promote_op(*, Td, Ta)
    PermuteMultiply(A.perm, A.vals .* D.diag)
end

function (*)(A::PermuteMultiply{Ta}, D::Diagonal{Td}) where {Td, Ta}
    T = Base.promote_op(*, Td, Ta)
    PermuteMultiply(A.perm, A.vals .* view(D.diag, A.perm))
end

# to self
function (*)(A::PermuteMultiply, B::PermuteMultiply)
    size(A, 1) == size(B, 1) || throw(DimensionMismatch())
    PermuteMultiply(B.perm[A.perm], A.vals.*view(B.vals, A.perm))
end

# to matrix
function (*)(A::PermuteMultiply, X::AbstractMatrix)
    size(X, 1) == size(A, 2) || throw(DimensionMismatch())
    return @views A.vals .* X[A.perm, :]   # this may be inefficient for sparse CSC matrix.
end

function (*)(X::AbstractMatrix, A::PermuteMultiply)
    mX, nX = size(X)
    nX == size(A, 1) || throw(DimensionMismatch())
    return @views (A.vals' .* X)[:, invperm(A.perm)]
end

# to sparse
function (*)(A::PermuteMultiply, X::SparseMatrixCSC)
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

function (*)(X::SparseMatrixCSC, A::PermuteMultiply)
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

############### kron ######################
import Base: kron
function kron(A::StridedMatrix{Tv}, B::PermuteMultiply{Tb}) where {Tv, Tb}
    mA, nA = size(A)
    nB = size(B, 1)
    perm = invperm(B.perm)
    nzval = Vector{promote_type(Tv, Tb)}(mA*nA*nB)
    rowval = Vector{Int}(mA*nA*nB)
    colptr = collect(1:mA:nA*nB*mA+1)
    z = 1
    @inbounds for j = 1:nA
        @inbounds for j2 = 1:nB
            p2 = perm[j2]
            val2 = B.vals[p2]
            ir = p2
            @inbounds @simd for i = 1:mA
                nzval[z] = A[i, j]*val2  # merge
                rowval[z] = ir
                z += 1
                ir += nB
            end
        end
    end
    SparseMatrixCSC(mA*nB, nA*nB, colptr, rowval, nzval)
end

function kron(A::PermuteMultiply{Ta}, B::StridedMatrix{Tb}) where {Tb, Ta}
    mB, nB = size(B)
    nA = size(A, 1)
    perm = invperm(A.perm)
    nzval = Vector{promote_type(Ta, Tb)}(mB*nA*nB)
    rowval = Vector{Int}(mB*nA*nB)
    colptr = collect(1:mB:nA*nB*mB+1)
    z = 1
    @inbounds for j = 1:nA
        colbase = (j-1)*nB
        p1 = perm[j]
        val2 = A.vals[p1]
        ir = (p1-1)*mB
        @inbounds for j2 = 1:nB
            @inbounds @simd for i2 = 1:mB
                nzval[z] = B[i2, j2]*val2  # merge
                rowval[z] = ir+i2
                z += 1
            end
        end
    end
    SparseMatrixCSC(nA*mB, nA*nB, colptr, rowval, nzval)
end

function kron(A::PermuteMultiply{Ta}, B::PermuteMultiply{Tb}) where {Ta, Tb}
    nA = size(A, 1)
    nB = size(B, 1)
    Tc = promote_type(Ta, Tb)
    vals = kron(A.vals, B.vals)
    perm = Vector{Int}(nB*nA)
    @inbounds for i = 1:nA
        start = (i-1)*nB
        permAi = (A.perm[i]-1)*nB
        @inbounds @simd for j = 1:nB
            perm[start+j] = permAi +B.perm[j]
        end
    end
    PermuteMultiply(perm, vals)
end

kron(A::PermuteMultiply, B::Diagonal) = kron(A, PermuteMultiply(B))
kron(A::Diagonal, B::PermuteMultiply) = kron(PermuteMultiply(A), B)

function kron(A::PermuteMultiply{Ta}, B::SparseMatrixCSC{Tb}) where {Ta, Tb}
    nA = size(A, 1)
    mB, nB = size(B)
    nV = nnz(B)
    perm = invperm(A.perm)
    nzval = Vector{promote_type(Ta, Tb)}(nA*nV)
    rowval = Vector{Int}(nA*nV)
    colptr = Vector{Int}(nA*nB+1)
    colptr[1] = 1
    @inbounds @simd for i in 1:nA
        start_row = (i-1)*nV
        start_ri = (perm[i]-1)*mB
        v0 = A.vals[perm[i]]
        @inbounds @simd for j = 1:nV
            nzval[start_row+j] = B.nzval[j]*v0
            rowval[start_row+j] = B.rowval[j] + start_ri
        end
        start_col = (i-1)*nB+1
        start_ci = (i-1)*nV
        @inbounds @simd for j = 1:nB
            colptr[start_col+j] = B.colptr[j+1] + start_ci
        end
    end
    SparseMatrixCSC(mB*nA, nB*nA, colptr, rowval, nzval)
end

function kron(A::SparseMatrixCSC{T}, B::PermuteMultiply{Tb}) where {T, Tb}
    nB = size(B, 1)
    mA, nA = size(A)
    nV = nnz(A)
    perm = invperm(B.perm)
    rowval = Vector{Int}(nB*nV)
    colptr = Vector{Int}(nA*nB+1)
    nzval = Vector{promote_type(T, Tb)}(nB*nV)
    z=1
    colptr[z] = 1
    @inbounds for i in 1:nA
        rstart = A.colptr[i]
        rend = A.colptr[i+1]-1
        @inbounds for k in 1:nB
            irow = perm[k]
            bval = B.vals[irow]
            irow_nB = irow - nB
            @inbounds @simd for r in rstart:rend
                rowval[z] = A.rowval[r]*nB+irow_nB
                nzval[z] = A.nzval[r]*bval
                z+=1
            end
            colptr[(i-1)*nB+k+1] = z
        end
    end
    SparseMatrixCSC(mA*nB, nA*nB, colptr, rowval, nzval)
end

####### diagonal kron ########
kron(A::Diagonal, B::Diagonal) = Diagonal(kron(A.diag, B.diag))
kron(A::StridedMatrix, B::Diagonal) = kron(A, PermuteMultiply(B))
kron(A::Diagonal, B::StridedMatrix) = kron(PermuteMultiply(A), B)
kron(A::Diagonal, B::SparseMatrixCSC) = kron(PermuteMultiply(A), B)
kron(A::SparseMatrixCSC, B::Diagonal) = kron(A, PermuteMultiply(B))
