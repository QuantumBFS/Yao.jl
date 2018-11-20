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
    mulcol!(v::AbstractVector, i::Int, f) -> VecOrMat

multiply col i of v by f inplace.
"""
function mulcol! end

"""
    mulrow!(v::AbstractVector, i::Int, f) -> VecOrMat

multiply row i of v by f inplace.
"""
function mulrow! end


"""
    matvec(x::VecOrMat) -> MatOrVec

Return vector if a matrix is a column vector, else untouched.
"""
function matvec end

@inline function swaprows!(v::AbstractMatrix{T}, i::Int, j::Int, f1, f2) where T
    @inbounds for c = 1:size(v, 2)
        local temp::T
        temp = v[i, c]
        v[i, c] = v[j, c]*f2
        v[j, c] = temp*f1
    end
    v
end

@inline function swaprows!(v::AbstractMatrix{T}, i::Int, j::Int) where T
    @inbounds for c = 1:size(v, 2)
        local temp::T
        temp = v[i, c]
        v[i, c] = v[j, c]
        v[j, c] = temp
    end
    v
end

@inline function swapcols!(v::AbstractMatrix{T}, i::Int, j::Int, f1, f2) where T
    @inbounds for c = 1:size(v, 1)
        local temp::T
        temp = v[c, i]
        v[c, i] = v[c, j]*f2
        v[c, j] = temp*f1
    end
    v
end

@inline function swapcols!(v::AbstractMatrix{T}, i::Int, j::Int) where T
    @inbounds for c = 1:size(v, 1)
        local temp::T
        temp = v[c, i]
        v[c, i] = v[c, j]
        v[c, j] = temp
    end
    v
end

@inline swapcols!(v::AbstractVector, args...) = swaprows!(v, args...)

@inline @inbounds function swaprows!(v::AbstractVector, i::Int, j::Int, f1, f2)
    temp = v[i]
    v[i] = v[j]*f2
    v[j] = temp*f1
    v
end

@inline @inbounds function swaprows!(v::AbstractVector, i::Int, j::Int)
    temp = v[i]
    v[i] = v[j]
    v[j] = temp
    v
end

@inline @inbounds function u1rows!(state::AbstractVector, i::Int, j::Int, a, b, c, d)
    w = state[i]
    v = state[j]
    state[i] = a*w+b*v
    state[j] = c*w+d*v
    state
end

@inline function u1rows!(state::AbstractMatrix, i::Int,j::Int, a, b, c, d)
    @inbounds for col = 1:size(state, 2)
        w = state[i, col]
        v = state[j, col]
        state[i, col] = a*w+b*v
        state[j, col] = c*w+d*v
    end
    state
end

@inline mulrow!(v::AbstractVector, i::Int, f) = (v[i] *= f; v)
@inline function mulrow!(v::AbstractMatrix, i::Int, f)
    @inbounds for j = 1:size(v, 2)
        v[i, j] *= f
    end
    v
end

@inline mulcol!(v::AbstractVector, i::Int, f) = (v[i] *= f; v)
@inline function mulcol!(v::AbstractMatrix, j::Int, f)
    @inbounds for i = 1:size(v, 1)
        v[i, j] *= f
    end
    v
end

matvec(x::AbstractMatrix) = size(x, 2) == 1 ? vec(x) : x
matvec(x::AbstractVector) = x

@inline function unrows!(state::AbstractVector, inds::AbstractVector, U::SDMatrix)
    @inbounds state[inds] = U*state[inds]
    state
end

@inline function unrows!(state::AbstractMatrix, inds::AbstractVector, U::SDMatrix)
    @inbounds for k in 1:size(state, 2)
        state[inds, k] = U*state[inds, k]
    end
    state
end

############# boost unrows! for sparse matrices ################
@inline unrows!(state::AbstractVector, inds::AbstractVector, U::IMatrix) = state

@inline function unrows!(state::AbstractVector, inds::AbstractVector, U::SDDiagonal)
    for i in 1:length(U.diag)
        @inbounds state[inds[i]] *= U.diag[i]
    end
    state
end

@inline function unrows!(state::AbstractMatrix, inds::AbstractVector, U::SDDiagonal)
    for j in 1:size(state, 2)
        for i in 1:length(U.diag)
            @inbounds state[inds[i],j] *= U.diag[i]
        end
    end
    state
end

@inline function unrows!(state::AbstractVector, inds::AbstractVector, U::SDPermMatrix)
    @inbounds state[inds] = state[inds[U.perm]] .* U.vals
    state
end

@inline function unrows!(state::AbstractMatrix, inds::AbstractVector, U::SDPermMatrix)
    @inbounds for k in 1:size(state, 2)
        state[inds, k] = state[inds[U.perm], k] .* U.vals
    end
    state
end

@inline function unrows!(state::AbstractVector, inds::AbstractVector, A::SDSparseMatrixCSC, work::AbstractVector)
    work .= 0
    @inbounds for col = 1:length(inds)
        xj = state[inds[col]]
        for j = A.colptr[col]:(A.colptr[col + 1] - 1)
            work[A.rowval[j]] += A.nzval[j]*xj
        end
    end
    state[inds] = work
    state
end

@inline function unrows!(state::AbstractMatrix, inds::AbstractVector, A::SDSparseMatrixCSC, work::Matrix)
    work .= 0
    @inbounds for k = 1:size(state, 2)
        for col = 1:length(inds)
            xj = state[inds[col],k]
            for j = A.colptr[col]:(A.colptr[col + 1] - 1)
                work[A.rowval[j], k] += A.nzval[j]*xj
            end
        end
        state[inds,k] = view(work, :, k)
    end
    state
end
