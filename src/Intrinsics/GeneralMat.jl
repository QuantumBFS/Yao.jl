using Yao
using Yao.Intrinsics
using Test
using LuxurySparse
using SparseArrays
using StaticArrays
using LinearAlgebra
using Yao.Intrinsics: autostatic
using Yao.Blocks

using BenchmarkTools

############################## General Methods ###########################
"""set specific col of a CSC matrix"""
@inline function setcol!(csc::SparseMatrixCSC, icol::Int, rowval::AbstractVector, nzval)
    @inbounds S = csc.colptr[icol]
    @inbounds E = csc.colptr[icol+1]-1
    @inbounds csc.rowval[S:E] = rowval
    @inbounds csc.nzval[S:E] = nzval
    csc
end

"""get specific col of a CSC matrix"""
@inline function getcol(csc::Union{SparseMatrixCSC, SSparseMatrixCSC}, icol::Int)
    @inbounds S = csc.colptr[icol]
    @inbounds E = csc.colptr[icol+1]-1
    @inbounds view(csc.rowval, S:E), view(csc.nzval, S:E)
end

"""
control-unitary
"""
function cunmat end

@inline function reorderU_iterator(nbit::Int, cbits::NTuple{C, Int}, cvals::NTuple{C, Int}, U::AbstractMatrix, locs::NTuple{M, Int}) where {C, M}
    # reorder a unirary matrix.
    U = all(diff(locs).>0) ? U : reorder(U, collect(locs)|>sortperm)
    locked_bits = [cbits..., locs...]
    locked_vals = [cvals..., zeros(Int, M)...]
    locs_raw = [i+1 for i in itercontrol(nbit, setdiff(1:nbit, locs), zeros(Int, nbit-M))]
    ic = itercontrol(nbit, locked_bits, locked_vals)
    return U |> autostatic, ic, locs_raw |> autostatic
end

cunmat(nbit::Int, cbits::NTuple, cvals::NTuple, U::IMatrix, locs::NTuple) = IMatrix{1<<nbit}()
unmat(nbit::Int, U::AbstractMatrix, locs::NTuple) = cunmat(nbit::Int, (), (), U, locs)

"""
    u1ij!(target, i, j, a, b, c, d)
single u1 matrix into a target matrix.

Note:
For coo, we take a additional parameter
    * ptr: starting position to store new data.
"""
function u1ij! end

############################### Dense Matrices ###########################
function u1mat(nbit::Int, U1::Union{SMatrix, StridedMatrix}, ibit::Int)
    mask = bmask(ibit)
    N = 1<<nbit
    a, c, b, d = U1
    step = 1<<(ibit-1)
    step_2 = 1<<ibit
    mat = SparseMatrixCSC(N, N, collect(1:2:2*N+1), Vector{Int}(undef, 2*N), Vector{eltype(U1)}(undef, 2*N))
    for j = 0:step_2:N-step
        @inbounds @simd for i = j+1:j+step
            u1ij!(mat, i, i+step, a, b, c, d)
        end
    end
    mat
end

@inline function u1ij!(csc::SparseMatrixCSC, i::Int,j::Int, a, b, c, d)
    csc.rowval[2*i-1] = i
    csc.rowval[2*i] = j
    csc.rowval[2*j-1] = i
    csc.rowval[2*j] = j

    csc.nzval[2*i-1] = a
    csc.nzval[2*i] = c
    csc.nzval[2*j-1] = b
    csc.nzval[2*j] = d
    csc
end

@inline function unij!(mat::SparseMatrixCSC, locs, U::Union{SMatrix, StridedMatrix})
   @simd for j = 1:size(U, 2)
        @inbounds setcol!(mat, locs[j], locs, view(U,:,j))
    end
    csc
end

function cunmat(nbit::Int, cbits::NTuple{C, Int}, cvals::NTuple{C, Int}, U0::AbstractMatrix, locs::NTuple{M, Int}) where {C, M}
    U, ic, locs_raw = reorderU_iterator(nbit, cbits, cvals, U0, locs)
    N = 1<<nbit
    MM = size(U, 1)
    NNZ = 1<<nbit + length(ic) * (length(U) - size(U,2))

    colptr = Vector{Int}(undef, N+1)
    rowval = Vector{Int}(undef, NNZ)
    colptr[1] = 1

    ctest = controller(cbits, cvals)
    @inbounds @simd for b in basis(nbit)
        if ctest(b)
            colptr[b+2] = colptr[b+1] + MM
        else
            colptr[b+2] = colptr[b+1] + 1
            rowval[colptr[b+1]] = b+1
        end
    end
    mat = SparseMatrixCSC(N, N, colptr, rowval, ones(eltype(U), NNZ))

    controldo(ic) do i
        unij!(mat, locs_raw+i, U)
    end
    mat
end

@testset "dense-u1mat-unmat" begin
    nbit = 4
    mmm = Rx(0.5) |> mat
    m1 = u1mat(nbit, mmm, 2)
    m2 = linop2dense(v-> u1apply!(v, mmm, 2), nbit)
    m3 = unmat(nbit, mmm, (2,))
    @test m1 ≈ m2
    @test m1 ≈ m3

    # test control not
    res = mat(I2) ⊗ mat(I2) ⊗ mat(P1) ⊗ mat(I2) + mat(I2) ⊗ mat(I2) ⊗ mat(P0) ⊗ mat(Rx(0.5))
    m3 = cunmat(nbit, (2,), (0,), mmm, (1,))
    @test m3 ≈ res
end

#= benchmark
nbit = 16
mmm = randn(ComplexF64, 2, 2)
@benchmark u1mat(nbit, $mmm, 2)  # ~600us
@benchmark unmat(nbit, $mmm, (2,))  # ~1.1ms
g = put(nbit, 2=>matrixgate(mmm))
@benchmark mat(g)
@test mat(g) == u1mat(nbit, mmm, 2) == unmat(nbit, mmm, (2,))
=#


############################### SparseMatrix ##############################
function cunmat(nbit::Int, cbits::NTuple{C, Int}, cvals::NTuple{C, Int}, U0::AbstractMatrix, locs::NTuple{M, Int}) where {C, M}
    U, ic, locs_raw = reorderU_iterator(nbit, cbits, cvals, U0, locs)
    N = 1<<nbit
    NNZ = 1<<nbit + length(ic) * (nnz(U) - size(U,2))
    ns = diff(U.colptr) |> autostatic

    rowval = Vector{Int}(undef, NNZ)
    colptr = Vector{Int}(undef, N+1)

    Ns = ones(Int, N)
    controldo(ic) do i
        Ns[locs_raw + i] = ns
    end
    colptr[1] = 1
    colptr[2:end] = cumsum(Ns) .+ 1
    @simd for j = 1:N
        S = colptr[j]
        E = colptr[j+1]-1
        if E == S
            @inbounds rowval[S] = j
        end
    end

    mat = SparseMatrixCSC(N, N, colptr, rowval, ones(eltype(U), NNZ))
    controldo(ic) do i
        unij!(mat, locs_raw+i, U)
    end
    mat
end

@inline function unij!(mat::SparseMatrixCSC, locs, U::Union{SSparseMatrixCSC,SparseMatrixCSC})
    @simd for j = 1:size(U, 2)
        rows, vals = getcol(U, j)
        @inbounds setcol!(mat, locs[j], view(locs, rows), vals)
    end
    csc
end

@testset "sparse-u1mat-unmat" begin
    nbit = 4
    # test control not
    res = mat(I2) ⊗ mat(I2) ⊗ mat(P1) ⊗ mat(I2) + mat(I2) ⊗ mat(I2) ⊗ mat(P0) ⊗ mat(P1)
    m3 = cunmat(nbit, (2,), (0,), mat(P1), (1,))
    @test m3 ≈ res
end

nbit = 16
mmm = mat(P1)
@benchmark unmat(nbit, $mmm, (2,))  # ~1.1ms
g = put(nbit, 2=>matrixgate(mmm))
@benchmark mat(g)
@test mat(g) == unmat(nbit, mmm, (2,))
#= benchmark
=#

############################# PermMatrix ###############################
@inline function unij!(pm::PermMatrix, locs::AbstractVector, U::Union{PermMatrix, SPermMatrix})
    M = size(U, 1)
    @inbounds pm.perm[locs] = locs[U.perm]
    @inbounds pm.vals[locs] = U.vals
    pm
end

function cunmat(nbit::Int, cbits::NTuple{C, Int}, cvals::NTuple{C, Int}, U0::AbstractMatrix, locs::NTuple{M, Int}) where {C, M}
    U, ic, locs_raw = reorderU_iterator(nbit, cbits, cvals, U0, locs)
    N = 1<<nbit
    pm = PermMatrix(Vector{Int}(undef, N), Vector{eltype(U)}(undef, N))
    controldo(ic) do i
        unij!(pm, locs_raw+i, U)
    end
    pm
end

@testset "perm-unij-unmat" begin
    perm = PermMatrix([1,2,3,4], [1,1,1,1.0])
    pm = unij!(copy(perm), [2,3,4], PermMatrix([3,1,2], [0.1,0.2,0.3]))
    @test pm ≈ PermMatrix([1,4,2,3], [1,0.1,0.2,0.3])
    pm = unij!(copy(perm), [2,3,4],PermMatrix([3,1,2], [0.1,0.2,0.3]) |> staticize)
    @test pm ≈ PermMatrix([1,4,2,3], [1,0.1,0.2,0.3])

    nbit = 4
    mmm = X |> mat
    m1 = unmat(nbit, mmm, (2,))
    m2 = linop2dense(v-> u1apply!(v, mmm, 2), nbit)
    @test m1 ≈ m2
end

#= benchmark
nbit = 16
mmm = X |> mat
@benchmark unmat(nbit, $mmm, (2,))  # ~300us
g = put(nbit, 2=>X)
@benchmark mat(g)
@test mat(g) == unmat(nbit, mmm, (2,))
=#

############################ Diagonal ##########################
function cunmat(nbit::Int, cbits::NTuple{C, Int}, cvals::NTuple{C, Int}, U0::AbstractMatrix, locs::NTuple{M, Int}) where {C, M}
    U, ic, locs_raw = reorderU_iterator(nbit, cbits, cvals, U0, locs)
    dg = Diagonal(collect(1:1<<nbit))
    controldo(ic) do i
        unij!(dg, locs_raw+i, U)
    end
    dg
end

@inline function unij!(dg::Union{SDiagonal, Diagonal}, locs, U)
    @inbounds dg.diag[locs] = U.diag
    dg
end

@testset "identity-unmat" begin
    nbit = 4
    mmm = Z |> mat
    m1 = unmat(nbit, mmm, (2,))
    m2 = linop2dense(v-> u1apply!(v, mmm, 2), nbit)
    @test m1 ≈ m2
end

#= benchmark
nbit = 16
mmm = Z |> mat
@benchmark unmat(nbit, $mmm, (2,))  # ~600us ???
g = put(nbit, 2=>Z)
@benchmark mat(g)
@test mat(g) == unmat(nbit, mmm, (2,))
=#

#=
@inline @inbounds function u1ij!(mat::StridedMatrix, i::Int, j::Int, a, b, c, d)
    mat[i, i] = a
    mat[i, j] = b
    mat[j, i] = c
    mat[j, j] = d
    mat
end

@inline function unij!(A::StridedMatrix, inds::AbstractVector, U::AbstractMatrix)
    @inbounds A[inds, inds] .= U
    state
end

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
    a1 = u1ij!(copy(a), 2, 3, 1,2,3,4)
    @test a1 ≈ [0 0 0 0;
                0 1 2 0;
                0 3 4 0;
                0 0 0 0]
    sa1 = u1ij!(copy(sa), 1, 2, 3, 1,2,3,4)
    @test sa1 |> Matrix == [0 0 0 0;
                0 1 2 0;
                0 3 4 0;
                0 0 0 0]
end

=#
