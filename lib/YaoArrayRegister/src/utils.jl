using LuxurySparse
using TupleTools
@static if hasmethod(TupleTools.diff, Tuple{Tuple{}})
    tuple_diff(args...) = TupleTools.diff(args...)
else
    tuple_diff(v::Tuple{}) = () # similar to diff([])
    tuple_diff(v::Tuple{Any}) = ()
    tuple_diff(v::Tuple) = (v[2] - v[1], tuple_diff(Base.tail(v))...)
end

"""
    sort_unitary(::Val{D}, U, locations::NTuple{N, Int}) -> U

Return an sorted unitary operator according to the locations.
"""
function sort_unitary(::Val{D}, U::AbstractMatrix, locs::NTuple{N,Int}) where {D,N}
    if all(each > 0 for each in tuple_diff(locs))
        return U
    else
        pm = TupleTools.sortperm(TupleTools.sortperm(locs))
        return reshape(permutedims(reshape(U, fill(D, 2*N)...), (pm..., pm .+ N...)), size(U))
    end
end

"""
    swaprows!(v::VecOrMat, i::Int, j::Int[, f1, f2]) -> VecOrMat

swap row i and row j of v inplace, with f1, f2 factors applied on i and j (before swap).
"""
function swaprows! end

Base.@propagate_inbounds function swaprows!(
    v::AbstractMatrix{T},
    i::Int,
    j::Int,
    f1,
    f2,
) where {T}
    for c = 1:size(v, 2)
        temp = v[i, c]
        v[i, c] = v[j, c] * f2
        v[j, c] = temp * f1
    end
    v
end

Base.@propagate_inbounds function swaprows!(v::AbstractMatrix{T}, i::Int, j::Int) where {T}
    for c = 1:size(v, 2)
        temp = v[i, c]
        v[i, c] = v[j, c]
        v[j, c] = temp
    end
    v
end

"""
    swapcols!(v::VecOrMat, i::Int, j::Int[, f1, f2]) -> VecOrMat

swap col i and col j of v inplace, with f1, f2 factors applied on i and j (before swap).
"""
function swapcols! end

Base.@propagate_inbounds function swapcols!(
    v::AbstractMatrix{T},
    i::Int,
    j::Int,
    f1,
    f2,
) where {T}
    for c = 1:size(v, 1)
        temp = v[c, i]
        v[c, i] = v[c, j] * f2
        v[c, j] = temp * f1
    end
    v
end

Base.@propagate_inbounds function swapcols!(v::AbstractMatrix{T}, i::Int, j::Int) where {T}
    for c = 1:size(v, 1)
        temp = v[c, i]
        v[c, i] = v[c, j]
        v[c, j] = temp
    end
    v
end

Base.@propagate_inbounds swapcols!(v::AbstractVector, args...) = swaprows!(v, args...)

Base.@propagate_inbounds function swaprows!(v::AbstractVector, i::Int, j::Int, f1, f2)
    temp = v[i]
    v[i] = v[j] * f2
    v[j] = temp * f1
    v
end

Base.@propagate_inbounds function swaprows!(v::AbstractVector, i::Int, j::Int)
    temp = v[i]
    v[i] = v[j]
    v[j] = temp
    v
end

"""
    u1rows!(state::VecOrMat, i::Int, j::Int, a, b, c, d) -> VecOrMat

apply u1 on row i and row j of state inplace.
"""
function u1rows! end

Base.@propagate_inbounds function u1rows!(state::AbstractVector, i::Int, j::Int, a, b, c, d)
    w = state[i]
    v = state[j]
    state[i] = a * w + b * v
    state[j] = c * w + d * v
    state
end

Base.@propagate_inbounds function u1rows!(state::AbstractMatrix, i::Int, j::Int, a, b, c, d)
    for col = 1:size(state, 2)
        w = state[i, col]
        v = state[j, col]
        state[i, col] = a * w + b * v
        state[j, col] = c * w + d * v
    end
    state
end

"""
    mulrow!(v::AbstractVector, i::Int, f) -> VecOrMat

multiply row i of v by f inplace.
"""
function mulrow! end

Base.@propagate_inbounds function mulrow!(v::AbstractVector, i::Int, f)
    v[i] *= f
    return v
end

Base.@propagate_inbounds function mulrow!(v::AbstractMatrix, i::Int, f)
    for j = 1:size(v, 2)
        v[i, j] *= f
    end
    return v
end

"""
    mulcol!(v::AbstractVector, i::Int, f) -> VecOrMat

multiply col i of v by f inplace.
"""
function mulcol! end

Base.@propagate_inbounds function mulcol!(v::AbstractVector, i::Int, f)
    v[i] *= f
    return v
end

Base.@propagate_inbounds function mulcol!(v::AbstractMatrix, j::Int, f)
    for i = 1:size(v, 1)
        v[i, j] *= f
    end
    return v
end

"""
    matvec(x::VecOrMat) -> MatOrVec

Return vector if a matrix is a column vector, else untouched.
"""
function matvec end

matvec(x::AbstractMatrix) = size(x, 2) == 1 ? vec(x) : x
matvec(x::AbstractVector) = x

Base.@propagate_inbounds function unrows!(
    state::AbstractVector,
    inds::AbstractVector,
    U::AbstractMatrix,
)
    state[inds] = U * state[inds]
    return state
end

Base.@propagate_inbounds function unrows!(
    state::AbstractMatrix,
    inds::AbstractVector,
    U::AbstractMatrix,
)
    for k = 1:size(state, 2)
        state[inds, k] = U * state[inds, k]
    end
    return state
end

############# boost unrows! for sparse matrices ################
@inline unrows!(state::AbstractVector, inds::AbstractVector, U::IMatrix) = state

Base.@propagate_inbounds function unrows!(
    state::AbstractVector,
    inds::AbstractVector,
    U::SDDiagonal,
)
    for i = 1:length(U.diag)
        state[inds[i]] *= U.diag[i]
    end
    return state
end

Base.@propagate_inbounds function unrows!(
    state::AbstractMatrix,
    inds::AbstractVector,
    U::SDDiagonal,
)
    for j = 1:size(state, 2)
        for i = 1:length(U.diag)
            state[inds[i], j] *= U.diag[i]
        end
    end
    state
end

Base.@propagate_inbounds function unrows!(
    state::AbstractVector,
    inds::AbstractVector,
    U::SDPermMatrix,
)
    state[inds] = state[inds[U.perm]] .* U.vals
    state
end

Base.@propagate_inbounds function unrows!(
    state::AbstractMatrix,
    inds::AbstractVector,
    U::SDPermMatrix,
)
    for k = 1:size(state, 2)
        state[inds, k] = state[inds[U.perm], k] .* U.vals
    end
    state
end

Base.@propagate_inbounds function unrows!(
    state::AbstractVector,
    inds::AbstractVector,
    A::SDSparseMatrixCSC,
    work::AbstractVector,
)
    work .= 0
    for col = 1:length(inds)
        xj = state[inds[col]]
        for j = A.colptr[col]:(A.colptr[col+1]-1)
            work[A.rowval[j]] += A.nzval[j] * xj
        end
    end
    state[inds] = work
    state
end

Base.@propagate_inbounds function unrows!(
    state::AbstractMatrix,
    inds::AbstractVector,
    A::SDSparseMatrixCSC,
    work::Matrix,
)
    work .= 0
    for k = 1:size(state, 2)
        for col = 1:length(inds)
            xj = state[inds[col], k]
            for j = A.colptr[col]:(A.colptr[col+1]-1)
                work[A.rowval[j], k] += A.nzval[j] * xj
            end
        end
        state[inds, k] = view(work, :, k)
    end
    state
end

using LinearAlgebra: Transpose
Base.convert(::Type{Transpose{T,Matrix{T}}}, arr::AbstractMatrix{T}) where {T} =
    transpose(Matrix(transpose(arr)))
Base.convert(t::Type{Transpose{T,Matrix{T}}}, arr::Transpose{T}) where {T} =
    invoke(convert, Tuple{Type{Transpose{T,Matrix{T}}},Transpose}, t, arr)

function ispow(x::Integer, d::Integer)
    r = log(x) / log(d)
    return round(Int, r) ≈ r
end

"""
    batch_normalize!(matrix)

normalize a batch of vector.
"""
function batch_normalize!(s::AbstractMatrix, p::Real = 2)
    B = size(s, 2)
    for i = 1:B
        normalize!(view(s, :, i), p)
    end
    s
end

"""
    batch_normalize

normalize a batch of vector.
"""
function batch_normalize(s::AbstractMatrix, p::Real = 2)
    ts = copy(s)
    batch_normalize!(ts, p)
end

# computes the trace norm of a matrix `m`.
trace_norm(m::AbstractMatrix) = nuclear_norm(m)
# computes the nuclear norm of a matrix `m`.
function nuclear_norm(m::AbstractMatrix)
    norm(svdvals(m), 1)
end

# ``\log_d(x)``
function logdi(x::Integer, d::Integer)
    @assert x > 0 && d > 0
    res = log(x) / log(d)
    r = round(Int, res)
    if !(res ≈ r)
        throw(ArgumentError("`$x` is not an integer power of `$d`."))
    end
    return r
end

"""
    autostatic(A[; threshold=8])

Staticize dynamic array `A` by a `threshold`.
"""
autostatic(A::AbstractVecOrMat; threshold::Int = 8) =
    length(A) > (1 << threshold) ? A : staticize(A)

################### Fidelity ###################
"""
    density_matrix_fidelity(ρ, σ)

General fidelity (including mixed states) between two density matrix for qudits.

### Definition

```math
F(\\rho, \\sigma) = {\\rm Tr}\\sqrt{\\sqrt{\\rho}\\sigma\\sqrt{\\rho}}
```
"""
function density_matrix_fidelity(ρ::AbstractMatrix, σ::AbstractMatrix)
    E1, U1 = eigen(Hermitian(ρ))
    E2, U2 = eigen(Hermitian(σ))
    E1 .= max.(E1, zero(eltype(E1)))
    E2 .= max.(E2, zero(eltype(E2)))
    sq1 = U1 * Diagonal(sqrt.(E1)) * U1'
    sq2 = U2 * Diagonal(sqrt.(E2)) * U2'
    return sum(svd(sq1 * sq2).S)
end


"""
    pure_state_fidelity(v1::Vector, v2::Vector)

fidelity for pure states.
"""
pure_state_fidelity(v1::AbstractVector, v2::AbstractVector) = abs(v1' * v2)

"""
    purification_fidelity(m1::Matrix, m2::Matrix)

Fidelity for mixed states via purification.

Reference:
    http://iopscience.iop.org/article/10.1088/1367-2630/aa6a4b/meta
"""
function purification_fidelity(m1::Matrix, m2::Matrix)
    O = m1' * m2
    return sum(svd(O).S)
end

"""
    linop2dense([T=ComplexF64], linear_map!::Function, n::Int; nlevel=2) -> Matrix

Returns the dense matrix representation given linear map function.
"""
linop2dense(linear_map!::Function, n::Int; nlevel=2) = linop2dense(ComplexF64, linear_map!, n; nlevel=nlevel)
linop2dense(::Type{T}, linear_map!::Function, n::Int; nlevel=2) where {T} =
    linear_map!(Matrix{T}(I, nlevel ^ n, nlevel ^ n))

"""
    general_controlled_gates(num_bit::Int, projectors::Vector{Tp}, cbits::Vector{Int}, gates::Vector{AbstractMatrix}, locs::Vector{Int}) -> AbstractMatrix

Return general multi-controlled gates in hilbert space of `num_bit` qudits,

* `projectors` are often chosen as `P0` and `P1` for inverse-Control and Control at specific position.
* `cbits` should have the same length as `projectors`, specifing the controling positions.
* `gates` are a list of controlled single qubit gates.
* `locs` should have the same length as `gates`, specifing the gates positions.
"""
function general_controlled_gates(
    n::Int,
    projectors::Vector{<:AbstractMatrix},
    cbits::Vector{Int},
    gates::Vector{<:AbstractMatrix},
    locs::Vector{Int},
)
    IMatrix(1 << n) - hilbertkron(n, projectors, cbits) +
    hilbertkron(n, vcat(projectors, gates), vcat(cbits, locs))
end

"""
    hilbertkron(num_bit::Int, gates::Vector{AbstractMatrix}, locs::Vector{Int}; nlevel=2) -> AbstractMatrix

Return general kronecher product form of gates in Hilbert space of `num_bit` qudits.

* `gates` are a list of matrices.
* `start_locs` should have the same length as `gates`, specifing the gates starting positions.
"""
function hilbertkron(num_bit::Int, ops::Vector{<:AbstractMatrix}, start_locs::Vector{Int}; nlevel=2)
    sizes = [logdi(size(op, 1), nlevel) for op in ops]
    start_locs = num_bit .- start_locs .- sizes .+ 2

    order = sortperm(start_locs)
    sorted_ops = ops[order]
    sorted_start_locs = start_locs[order]
    num_ids = vcat(
        sorted_start_locs[1] - 1,
        diff(push!(sorted_start_locs, num_bit + 1)) .- sizes[order],
    )

    _wrap_identity(sorted_ops, num_ids, nlevel)
end
diff(v::AbstractVector) = Base.diff(v)
diff(v::Tuple) = TupleTools.diff(v)

# kron, and wrap matrices with identities.
function _wrap_identity(
    data_list::Vector{T},
    num_bit_list::Vector{Int},
    nlevel
) where {T<:AbstractMatrix}
    length(num_bit_list) == length(data_list) + 1 || throw(ArgumentError())
    reduce(
        zip(data_list, num_bit_list[2:end]);
        init = IMatrix(nlevel ^ num_bit_list[1]),
    ) do x, y
        fastkron(fastkron(x, y[1]), IMatrix(nlevel ^ y[2]))
    end
end

batched_kron(a, b, c, xs...) =
    Base.afoldl(batched_kron, (batched_kron)((batched_kron)(a, b), c), xs...)

function batched_kron(A::AbstractArray{T,3}, B::AbstractArray{S,3}) where {T,S}
    @assert size(A, 3) == size(B, 3) "batch size mismatch"
    C = Array{Base.promote_op(*, T, S),3}(
        undef,
        size(A, 1) * size(B, 1),
        size(A, 2) * size(B, 2),
        size(A, 3),
    )
    return batched_kron!(C, A, B)
end

function batched_kron!(
    C::Array{T,3},
    A::AbstractArray{T1,3},
    B::AbstractArray{T2,3},
) where {T,T1,T2}
    @assert !Base.has_offset_axes(A, B)
    m, n = size(A)
    p, q = size(B)
    @inbounds for k = 1:size(C, 3)
        for s = 1:n, r = 1:m, w = 1:q, v = 1:p
            C[p*(r-1)+v, q*(s-1)+w, k] = A[r, s, k] * B[v, w, k]
        end
    end
    return C
end

@static if !@isdefined(kron!)
    export kron!
    # NOTE: JuliaLang/julia/pull/31069 includes this function
    function kron!(
        C::AbstractMatrix{T},
        A::AbstractMatrix{T1},
        B::AbstractMatrix{T2},
    ) where {T,T1,T2}
        @assert !Base.has_offset_axes(A, B)
        m = 1
        @inbounds for j = 1:size(A, 2), l = 1:size(B, 2), i = 1:size(A, 1)
            aij = A[i, j]
            for k = 1:size(B, 1)
                C[m] = aij * B[k, l]
                m += 1
            end
        end
        return C
    end
end

function matchtype(::Type{T}, A::AbstractArray{T2}) where {T,T2}
    return copyto!(similar(A, T), A)
end
function matchtype(::Type{T}, A::AbstractArray{T}) where {T}
    return A
end

@static if !hasmethod(IMatrix{Float64}, Tuple{Int})
    LuxurySparse.IMatrix{T}(n::Int) where T = IMatrix{n,T}()
end
