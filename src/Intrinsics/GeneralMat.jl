using Yao
using Yao.Intrinsics
using Test
using LuxurySparse
using SparseArrays
using StaticArrays

using BenchmarkTools

@inline @inbounds function u1ij!(mat::AbstractMatrix, i::Int, j::Int, a, b, c, d)
    mat[i, i] = a
    mat[i, j] = b
    mat[j, i] = c
    mat[j, j] = d
    mat
end

"""
single u1 matrix into coo matrix.
    * ptr: starting position to store new data.
"""
@inline function u1ij!(coo::SparseMatrixCOO, ptr::Int, i::Int,j::Int, a, b, c, d)
    coo.is[ptr] = i
    coo.is[ptr+1] = i
    coo.is[ptr+2] = j
    coo.is[ptr+3] = j

    coo.js[ptr] = i
    coo.js[ptr+1] = j
    coo.js[ptr+2] = i
    coo.js[ptr+3] = j

    coo.vs[ptr] = a
    coo.vs[ptr+1] = b
    coo.vs[ptr+2] = c
    coo.vs[ptr+3] = d
    coo
end

@testset "u1ij" begin
    a = zeros(4, 4)
    sa = allocated_coo(Float64, 4, 4, 4)
    println(typeof(sa))
    u1ij!(a, 2, 3, 1,2,3,4)
    @test a ≈ [0 0 0 0;
                0 1 2 0;
                0 3 4 0;
                0 0 0 0]
    u1ij!(sa, 1, 2, 3, 1,2,3,4)
    @test sa |> Matrix == [0 0 0 0;
                0 1 2 0;
                0 3 4 0;
                0 0 0 0]
end

function u1mat(nbit::Int, U1::AbstractMatrix{T}, ibit::Int) where T
    mask = bmask(ibit)
    N = 1<<nbit
    coo = allocated_coo(T, N, N, 2*N)
    a, c, b, d = U1
    step = 1<<(ibit-1)
    step_2 = 1<<ibit
    ptr = 1
    for j = 0:step_2:N-step
        @inbounds @simd for i = j+1:j+step
            u1ij!(coo, ptr, i, i+step, a, b, c, d)
            ptr += 4
        end
    end
    # sparse function cost unreasonablly a lot here.
    SparseMatrixCSC(coo)
end

@testset "u1mat" begin
    nbit = 4
    mmm = Rx(0.5) |> mat
    m1 = u1mat(nbit, mmm, 2)
    m2 = linop2dense(v-> u1apply!(v, mmm, 2), nbit)
    @test m1 ≈ m2
end

nbit = 16
mmm = randn(ComplexF64, 2, 2)
g = put(nbit, 2=>matrixgate(mmm))
@benchmark u1mat(nbit, mmm, 2)
@benchmark mat(g)
@test mat(g) == u1mat(nbit, mmm, 2)

@inline function unij!(A::AbstractMatrix, inds::AbstractVector, U::AbstractMatrix)
    @inbounds A[inds, inds] .= U
    state
end

@inline function unrows!(state::Matrix, inds::AbstractVector, U::AbstractMatrix)
    @inbounds @simd for k in 1:size(state, 2)
        state[inds, k] .= U*view(state, inds, k)
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
    @inbounds state[inds].=work
    state
end

@inline function unrows!(state::Matrix, inds::AbstractVector, U::PermMatrix, work::Matrix)
    @inbounds for k in 1:size(state, 2)
        @inbounds @simd for i = 1:length(inds)
            work[i, k] = state[inds[U.perm[i]], k] * U.vals[i]
        end
        state[inds, k].=work[:, k]
    end
    state
end

@inline function unrows!(state::Vector, inds::AbstractVector, A::Union{SSparseMatrixCSC, SparseMatrixCSC}, work::Vector)
    work.=0
    @inbounds for col = 1:length(inds)
        xj = state[inds[col]]
        @inbounds @simd for j = A.colptr[col]:(A.colptr[col + 1] - 1)
            work[A.rowval[j]] += A.nzval[j]*xj
        end
    end
    state[inds] .= work
    state
end

@inline function unrows!(state::Matrix, inds::AbstractVector, A::Union{SSparseMatrixCSC, SparseMatrixCSC}, work::Matrix)
    work.=0
    @inbounds for k = 1:size(state, 2)
        @inbounds for col = 1:length(inds)
            xj = state[inds[col],k]
            @inbounds @simd for j = A.colptr[col]:(A.colptr[col + 1] - 1)
                work[A.rowval[j], k] += A.nzval[j]*xj
            end
        end
        state[inds,k] .= work[:,k]
    end
    state
end
function _unmat(nbit::Int, U::Union{SMatrix, Matrix}, locs_raw::Union{SVector, Vector}, ic::IterControl)
    nr = size(U, 1)
    coo = allocated_coo(T, N, N, nr*N)
    controldo(ic) do i
        unij!(coo, locs_raw+i, U)
    end
    SparseMatrixCSC(coo)
end

function _unmat(nbit::Int, U::Union{SDiagonal, Diagonal}, locs_raw::Union{SVector, Vector}, ic::IterControl)
    dg = Diagonal(Vector{T}(1<<nbit))
    controldo(ic) do i
        unij!(dg, locs_raw+i, U)
    end
    dg
end

function _unmat(nbit::Int, U::PermMatrix, locs_raw::Union{SVector, Vector}, ic::IterControl)
    N = 1<<nbit
    pm = PermMatrix(Vector{Int}(N), Vector{T}(N))
    controldo(ic) do i
        unij!(pm, locs_raw+i, U)
    end
    dg
end

function _unmat(nbit::Int, U::Union{SSparseMatrixCSC, SparseMatrixCSC}, locs_raw::Union{SVector, Vector}, ic::IterControl)
    coo = allocated_coo(T, N, N, N÷size(U, 1)*length(U.nzval))
    controldo(ic) do i
        unij!(coo, locs_raw+i, U)
    end
    SparseMatrixCSC(coo)
end


"""
turn a vector/matrix to static vector/matrix (only if its length <= 256).
"""
autostatic(A::AbstractVecOrMat) = length(A) > 1<<8 ? A : A |> statify

"""
control-unitary
"""
function cunmat end

function cunmat(nbit::Int, cbits::NTuple{C, Int}, cvals::NTuple{C, Int}, U::AbstractMatrix, locs::NTuple{M, Int}) where {C, M}
    # reorder a unirary matrix.
    U = all(diff(locs).>0) ? U : reorder(U, collect(locs)|>sortperm)
    N, MM = nqubits(state), size(U, 1)
    locked_bits = [cbits..., locs...]
    locked_vals = [cvals..., zeros(Int, M)...]
    locs_raw = [i+1 for i in itercontrol(N, setdiff(1:N, locs), zeros(Int, N-M))]
    ic = itercontrol(N, locked_bits, locked_vals)
    _unmat(nbit, U |> autostatic, locs_raw |> autostatic, ic)
end

cunmat(nbit::Int, cbits::NTuple, cvals::NTuple, U::IMatrix, locs::NTuple) = IMatrix{1<<nbit}()

unmat(nbit::Int, U::AbstractMatrix, locs::NTuple) = cunmat(nbit::Int, (), (), U, locs)
