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

matvec(x::Matrix) = size(x, 2) == 1 ? vec(x) : x
matvec(x::Vector) = x

@inline function unrows!(state::Vector, inds::AbstractVector, U::AbstractMatrix)
    state[inds] = U*view(state, inds)
    state
end

@inline function unrows!(state::Matrix, inds::AbstractVector, U::AbstractMatrix)
    @simd for k in 1:size(state, 2)
        @inbounds state[inds, k] .= U*view(state, inds, k)
    end
    state
end

############# boost unrows! for sparse matrices ################
@inline unrows!(state::Vector, inds::AbstractVector, U::IMatrix) = state

for MT in [:Matrix, :Vector]
    @eval @inline function unrows!(state::$MT, inds::AbstractVector, U::Union{Diagonal, SDiagonal})
        @simd for i in 1:length(U.diag)
            @inbounds mulrow!(state, inds[i], U.diag[i])
        end
        state
    end
end

@inline function unrows!(state::Vector, inds::AbstractVector, U::PermMatrix, work::Vector)
    @simd for i = 1:length(inds)
        @inbounds work[i] = state[inds[U.perm[i]]] * U.vals[i]
    end
    @inbounds state[inds].=work
    state
end

@inline function unrows!(state::Matrix, inds::AbstractVector, U::PermMatrix, work::Matrix)
    for k in 1:size(state, 2)
        @simd for i = 1:length(inds)
            @inbounds work[i, k] = state[inds[U.perm[i]], k] * U.vals[i]
        end
        @inbounds state[inds, k].=work
    end
    state
end

@inline function unrows!(state::Vector, inds::AbstractVector, A::Union{SSparseMatrixCSC, SparseMatrixCSC}, work::Vector)
    @inbounds work.=0
    for col = 1:length(inds)
        xj = state[inds[col]]
        @simd for j = A.colptr[col]:(A.colptr[col + 1] - 1)
            @inbounds work[A.rowval[j]] += A.nzval[j]*xj
        end
    end
    @inbounds state[inds] .= work
    state
end

@inline function unrows!(state::Matrix, inds::AbstractVector, A::Union{SSparseMatrixCSC, SparseMatrixCSC}, work::Matrix)
    @inbounds work.=0
    for k = 1:size(state, 2)
        for col = 1:length(inds)
            xj = state[inds[col],k]
            @simd for j = A.colptr[col]:(A.colptr[col + 1] - 1)
                @inbounds work[A.rowval[j], k] += A.nzval[j]*xj
            end
        end
    end
    @inbounds state[inds] .= work
    state
end

