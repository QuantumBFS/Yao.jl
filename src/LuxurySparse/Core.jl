"""
    swaprows(v::VecOrMat, i::Int, j::Int, [f1, f2]) -> VecOrMat

Swap two rows i and j of a matrix/vector, f1 and f2 are two factors applied on i-th and j-th element of input matrix/vector, default is 1.
"""
function swaprows end

"""
    mulrow(v::VecOrMat, i::Int, f) -> VecOrMat

mulrow row i by f.
"""
function mulrow end

"""
    matvec(x::VecOrMat) -> MatOrVec

Return vector if a matrix is a column vector, else untouched.
"""
function matvec end

function swaprows(v::Matrix{T}, i::Int, j::Int, f1, f2) where T
    @simd for c = 1:size(v, 2)
        local temp::T
        temp = v[i, c]
        @inbounds v[i, c] = v[j, c]*f2
        @inbounds v[j, c] = temp*f1
    end
    v
end

function swaprows(v::Matrix{T}, i::Int, j::Int) where T
    @simd for c = 1:size(v, 2)
        local temp::T
        temp = v[i, c]
        @inbounds v[i, c] = v[j, c]
        @inbounds v[j, c] = temp
    end
    v
end

function swaprows(v::Vector, i::Int, j::Int, f1, f2)
    temp = v[i]
    @inbounds v[i] = v[j]*f2
    @inbounds v[j] = temp*f1
    v
end

function swaprows(v::Vector, i::Int, j::Int)
    temp = v[i]
    @inbounds v[i] = v[j]
    @inbounds v[j] = temp
    v
end

mulrow(v::Vector, i::Int, f) = (v[i] *= f; v)
@inline function mulrow(v::Matrix, i::Int, f)
    @simd for j = 1:size(v, 2)
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
