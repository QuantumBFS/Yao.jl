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
function kron(A::PermuteMultiply{Ta}, B::PermuteMultiply{Tb}) where {Ta, Tb}
     nA = size(A, 1)
     nB = size(B, 1)
     Tc = promote_type(Ta, Tb)
     vals = Vector{Tc}(nB*nA)
     perm = Vector{Int}(nB*nA)
     for i = 1:nA
        perm[(i-1)*nB+1:i*nB] = (A.perm[i]-1)*nB +B.perm
        vals[(i-1)*nB+1:i*nB] = A.vals[i]*B.vals
     end
     PermuteMultiply(perm, vals)
end

function kron(A::PermuteMultiply{Ta}, B::Diagonal{Tb}) where {Ta, Tb}
    nB = size(B, 1)
    nA = size(A, 1)
    Tc = promote_type(Ta, Tb)
    vals = Vector{Tc}(nB*nA)
    perm = Vector{Int}(nB*nA)
    for i = 1:nA
        perm[(i-1)*nB+1:i*nB] = (A.perm[i]-1)*nB + collect(1:nB)
        vals[(i-1)*nB+1:i*nB] = A.vals[i]*B.diag
    end
    PermuteMultiply(perm, vals)
end

function kron(A::Diagonal{Ta}, B::PermuteMultiply{Tb}) where {Ta, Tb}
     nA = size(A, 1)
     nB = size(B, 1)
     Tc = promote_type(Ta, Tb)
     vals = Vector{Tc}(nB*nA)
     perm = Vector{Int}(nB*nA)
     for i = 1:nA
        perm[(i-1)*nB+1:i*nB] = (i-1)*nB+B.perm
        vals[(i-1)*nB+1:i*nB] = A.diag[i]*B.vals
     end
     PermuteMultiply(perm, vals)
end

kron(A::PermuteMultiply, B::SparseMatrixCSC) = kron(sparse(A), B)
kron(A::SparseMatrixCSC, B::PermuteMultiply) = kron(A, sparse(B))
