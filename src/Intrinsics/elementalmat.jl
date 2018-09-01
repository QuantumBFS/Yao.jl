@inline @inbounds function u1ij!(mat::AbstractMatrix, i::Int, j::Int, a, b, c, d)
    mat[i, i] = a
    mat[i, j] = b
    mat[j, i] = c
    mat[j, j] = d
    mat
end

@inline function u1ij!(coo::NTuple{3, Vector}, i::Int,j::Int, a, b, c, d)
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

@inline function unrows!(state::Vector, inds::AbstractVector, U::PermMatrix, work::Vector)
    @inbounds @simd for i = 1:length(inds)
        work[i] = state[inds[U.perm[i]]] * U.vals[i]
    end
    @inbounds state[inds] = work
    state
end

@inline function unrows!(state::Matrix, inds::AbstractVector, U::PermMatrix, work::Matrix)
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
        state[inds,k] = view(work, :,k)
    end
    state
end
