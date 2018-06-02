"""
    PermMatrix{Tv, Ti}(perm::Vector{Ti}, vals::Vector{Tv}) where {Tv, Ti<:Integer}
    PermMatrix(perm::Vector{Ti}, vals::Vector{Tv}) where {Tv, Ti}
    PermMatrix(ds::AbstractMatrix)

PermMatrix represents a special kind linear operator: Permute and Multiply, which means `M * v = v[perm] * val`
Optimizations are used to make it much faster than `SparseMatrixCSC`.

* `perm` is the permutation order,
* `vals` is the multiplication factor.

[Generalized Permutation Matrix](https://en.wikipedia.org/wiki/Generalized_permutation_matrix)
"""
struct PermMatrix{Tv, Ti<:Integer} <: AbstractMatrix{Tv}
    perm::Vector{Ti}   # new orders
    vals::Vector{Tv}  # multiplied values.

    function PermMatrix{Tv, Ti}(perm::Vector{Ti}, vals::Vector{Tv}) where {Tv, Ti<:Integer}
        if length(perm) != length(vals)
            throw(DimensionMismatch("permutation ($(length(perm))) and multiply ($(length(vals))) length mismatch."))
        end
        new{Tv, Ti}(perm, vals)
    end
end

function PermMatrix(perm::Vector{Ti}, vals::Vector{Tv}) where {Tv, Ti}
    PermMatrix{Tv,Ti}(perm, vals)
end

PermMatrix(dmat::Diagonal) = PermMatrix(collect(1:size(dmat, 1)), dmat.diag)

function PermMatrix(ds::AbstractMatrix)
    i,j,v = findnz(ds)
    j == collect(1:size(ds, 2)) || throw(ArgumentError("This is not a PermMatrix"))
    order = invperm(i)
    PermMatrix(order, v[order])
end

################# Array Functions ##################

size(M::PermMatrix) = (length(M.perm), length(M.perm))
function size(A::PermMatrix, d::Integer)
    if d < 1
        throw(ArgumentError("dimension must be ≥ 1, got $d"))
    elseif d<=2
        return length(A.perm)
    else
        return 1
    end
end
getindex(M::PermMatrix, i::Integer, j::Integer) = M.perm[i] == j ? M.vals[i] : 0
copyto!(A::PermMatrix, B::PermMatrix) = (copyto!(A.perm, B.perm); copyto!(A.vals, B.vals); A)

"""
    pmrand(T::Type, n::Int) -> PermMatrix

Return random PermMatrix.
"""
function pmrand end

pmrand(T::Type, n::Int) = PermMatrix(randperm(n), randn(T, n))
pmrand(n::Int) = PermMatrix(randperm(n), randn(n))

similar(x::PermMatrix{Tv, Ti}) where {Tv, Ti} = PermMatrix{Tv, Ti}(similar(x.perm), similar(x.vals))
similar(x::PermMatrix{Tv, Ti}, ::Type{T}) where {Tv, Ti, T} = PermMatrix{T, Ti}(similar(x.perm), similar(x.vals, T))

function sparse(M::PermMatrix)
    n = size(M, 1)
    dropzeros(sparse(collect(1:n), M.perm, M.vals, n, n))
end

# TODO: rewrite this
# function show(io::IO, M::PermMatrix)
#     println("PermMatrix")
#     for item in zip(M.perm, M.vals)
#         i, p = item
#         println("- ($i) * $p")
#     end
# end

######### sparse array interfaces  #########
nnz(M::PermMatrix) = length(M.vals)
nonzeros(M::PermMatrix) = M.vals

# TODO: implement this
dropzeros!(M::PermMatrix) = M
