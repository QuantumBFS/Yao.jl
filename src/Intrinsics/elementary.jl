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

@inline function swaprows!(v::Matrix{T}, i::Int, j::Int, f1, f2) where T
    @inbounds @simd for c = 1:size(v, 2)
        local temp::T
        temp = v[i, c]
        v[i, c] = v[j, c]*f2
        v[j, c] = temp*f1
    end
    v
end

@inline function swaprows!(v::Matrix{T}, i::Int, j::Int) where T
    @inbounds @simd for c = 1:size(v, 2)
        local temp::T
        temp = v[i, c]
        v[i, c] = v[j, c]
        v[j, c] = temp
    end
    v
end

@inline function swapcols!(v::Matrix{T}, i::Int, j::Int, f1, f2) where T
    @inbounds @simd for c = 1:size(v, 1)
        local temp::T
        temp = v[c, i]
        v[c, i] = v[c, j]*f2
        v[c, j] = temp*f1
    end
    v
end

@inline function swapcols!(v::Matrix{T}, i::Int, j::Int) where T
    @inbounds @simd for c = 1:size(v, 1)
        local temp::T
        temp = v[c, i]
        v[c, i] = v[c, j]
        v[c, j] = temp
    end
    v
end

@inline swapcols!(v::Vector, args...) = swaprows!(v, args...)

@inline @inbounds function swaprows!(v::Vector, i::Int, j::Int, f1, f2)
    temp = v[i]
    v[i] = v[j]*f2
    v[j] = temp*f1
    v
end

@inline @inbounds function swaprows!(v::Vector, i::Int, j::Int)
    temp = v[i]
    v[i] = v[j]
    v[j] = temp
    v
end

@inline @inbounds function u1rows!(state::Vector, i::Int, j::Int, a, b, c, d)
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
    @inbounds @simd for j = 1:size(v, 2)
        v[i, j] *= f
    end
    v
end

@inline mulcol!(v::Vector, i::Int, f) = (v[i] *= f; v)
@inline function mulcol!(v::Matrix, j::Int, f)
    @inbounds @simd for i = 1:size(v, 1)
        v[i, j] *= f
    end
    v
end

matvec(x::Matrix) = size(x, 2) == 1 ? vec(x) : x
matvec(x::Vector) = x

@inline function unrows!(state::Vector, inds::AbstractVector, U::AbstractMatrix)
    @inbounds state[inds] = U*view(state, inds)
    state
end

@inline function unrows!(state::Matrix, inds::AbstractVector, U::AbstractMatrix)
    @inbounds @simd for k in 1:size(state, 2)
        state[inds, k] = U*view(state, inds, k)
    end
    state
end

############# boost unrows! for sparse matrices ################
@inline unrows!(state::Vector, inds::AbstractVector, U::IMatrix) = state

for MT in [:Matrix, :Vector]
    @eval @inline function unrows!(state::$MT, inds::AbstractVector, U::Union{Diagonal, SDiagonal})
        @inbounds @simd for i in 1:length(U.diag)
            mulrow!(state, inds[i], U.diag[i])
        end
        state
    end
end

@inline function unrows!(state::Vector, inds::AbstractVector, U::Union{SPermMatrix, PermMatrix}, work::Vector)
    @inbounds @simd for i = 1:length(inds)
        work[i] = state[inds[U.perm[i]]] * U.vals[i]
    end
    @inbounds state[inds] = work
    state
end

@inline function unrows!(state::Matrix, inds::AbstractVector, U::Union{SPermMatrix, PermMatrix}, work::Matrix)
    @inbounds for k in 1:size(state, 2)
        @inbounds @simd for i = 1:length(inds)
            work[i, k] = state[inds[U.perm[i]], k] * U.vals[i]
        end
        state[inds, k] = view(work, :, k)
    end
    state
end

@inline function unrows!(state::Vector, inds::AbstractVector, A::Union{SSparseMatrixCSC, SparseMatrixCSC}, work::Vector)
    work .= 0
    @inbounds for col = 1:length(inds)
        xj = state[inds[col]]
        @inbounds @simd for j = A.colptr[col]:(A.colptr[col + 1] - 1)
            work[A.rowval[j]] += A.nzval[j]*xj
        end
    end
    state[inds] = work
    state
end

@inline function unrows!(state::Matrix, inds::AbstractVector, A::Union{SSparseMatrixCSC, SparseMatrixCSC}, work::Matrix)
    work .= 0
    @inbounds for k = 1:size(state, 2)
        @inbounds for col = 1:length(inds)
            xj = state[inds[col],k]
            @inbounds @simd for j = A.colptr[col]:(A.colptr[col + 1] - 1)
                work[A.rowval[j], k] += A.nzval[j]*xj
            end
        end
        state[inds,k] = view(work, :, k)
    end
    state
end
