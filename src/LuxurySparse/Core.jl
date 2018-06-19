"""
    swaprows!(v::VecOrMat, i::Int, j::Int, [f1, f2]) -> VecOrMat

Swap two rows i and j of a matrix/vector, f1 and f2 are two factors applied on i-th and j-th element of input matrix/vector, default is 1.
"""
function swaprows! end

"""
    mulrow!(v::VecOrMat, i::Int, f) -> VecOrMat

multiply row i by f.
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

@inline function swaprows!(v::Matrix{T}, i::Int, j::Int, f1, f2) where T
    @simd for c = 1:size(v, 2)
        local temp::T
        temp = v[i, c]
        @inbounds v[i, c] = v[j, c]*f2
        @inbounds v[j, c] = temp*f1
    end
    v
end

@inline function swaprows!(v::Matrix{T}, i::Int, j::Int) where T
    @simd for c = 1:size(v, 2)
        local temp::T
        temp = v[i, c]
        @inbounds v[i, c] = v[j, c]
        @inbounds v[j, c] = temp
    end
    v
end

@inline function swapcols!(v::Matrix{T}, i::Int, j::Int, f1, f2) where T
    @simd for c = 1:size(v, 1)
        local temp::T
        temp = v[c, i]
        @inbounds v[c, i] = v[c, j]*f2
        @inbounds v[c, j] = temp*f1
    end
    v
end

@inline function swapcols!(v::Matrix{T}, i::Int, j::Int) where T
    @simd for c = 1:size(v, 1)
        local temp::T
        temp = v[c, i]
        @inbounds v[c, i] = v[c, j]
        @inbounds v[c, j] = temp
    end
    v
end

@inline swapcols!(v::Vector, args...) = swaprows!(v, args...)

@inline function swaprows!(v::Vector, i::Int, j::Int, f1, f2)
    temp = v[i]
    @inbounds v[i] = v[j]*f2
    @inbounds v[j] = temp*f1
    v
end

@inline function swaprows!(v::Vector, i::Int, j::Int)
    temp = v[i]
    @inbounds v[i] = v[j]
    @inbounds v[j] = temp
    v
end

@inline function u1rows!(state::Vector, i::Int, j::Int, a, b, c, d)
    w = state[i]
    v = state[j]
    state[i] = a*w+b*v
    state[j] = c*w+d*v
    state
end

@inline function u1rows!(state::Matrix, i::Int,j::Int, a, b, c, d)
    @inbounds @simd for col = 1:size(state, 2)
        w = state[i, col]
        v = state[j, col]
        state[i, col] = a*w+b*v
        state[j, col] = c*w+d*v
    end
    state
end

@inline mulrow!(v::Vector, i::Int, f) = (v[i] *= f; v)
@inline function mulrow!(v::Matrix, i::Int, f)
    @simd for j = 1:size(v, 2)
        @inbounds v[i, j] *= f
    end
    v
end

@inline mulcol!(v::Vector, i::Int, f) = (v[i] *= f; v)
@inline function mulcol!(v::Matrix, j::Int, f)
    @simd for i = 1:size(v, 1)
        @inbounds v[i, j] *= f
    end
    v
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
matvec(x::Matrix) = size(x, 2) == 1 ? vec(x) : x
matvec(x::Vector) = x
