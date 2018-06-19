"""
    swaprows!(v::VecOrMat, i::Int, j::Int[, f1, f2]) -> VecOrMat

swap row i and row j of v inplace, with f1, f2 factors applied on i and j (before swap).
"""
function swaprows! end

"""
    swapcols!(v::VecOrMat, i::Int, j::Int[, f1, f2]) -> VecOrMat

swap col i and col j of v inplace, with f1, f2 factors applied on i and j (before swap).
"""
function swapcols! end

"""
    u1rows!(state::VecOrMat, i::Int, j::Int, a, b, c, d) -> VecOrMat

apply u1 on row i and row j of state inplace.
"""
function u1rows! end

"""
    mulcol!(v::Vector, i::Int, f) -> VecOrMat

multiply col i of v by f inplace.
"""
function mulcol! end

"""
    mulrow!(v::Vector, i::Int, f) -> VecOrMat

multiply row i of v by f inplace.
"""
function mulrow! end


"""
    matvec(x::VecOrMat) -> MatOrVec

Return vector if a matrix is a column vector, else untouched.
"""
function matvec end

"""
    notdense(M) -> Bool

Return true if a matrix is not dense.

Note:
It is not exactly same as isparse, e.g. Diagonal, IMatrix and PermMatrix are both notdense but not isparse.
"""
function notdense end

notdense(M)::Bool = issparse(M)
@static if VERSION >= v"0.7-"
notdense(x::Transpose) = notdense(parent(x))
notdense(x::Adjoint) = notdense(parent(x))
end

"""faster invperm"""
function fast_invperm(order)
    v = similar(order)
    @inbounds @simd for i=1:length(order)
        v[order[i]] = i
    end
    v
end

dropzeros!(A::Diagonal) = A
