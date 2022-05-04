using LinearAlgebra, StaticArrays, LuxurySparse, SparseArrays
using Test
import YaoArrayRegister: swaprows!, swapcols!, mulrow!, mulcol!, u1rows!, unrows!,
    batch_normalize, hilbertkron, batch_normalize!, batched_kron, rot_mat, invorder, reorder, logdi

@testset "swaprows! & mulrow!" begin
    a = [1, 2, 3, 5.0]
    A = Float64.(reshape(1:8, 4, 2))
    @test swaprows!(copy(a), 2, 4) ≈ [1, 5, 3, 2]
    @test swaprows!(copy(a), 2, 4, 0.1, 0.2) ≈ [1, 1, 3, 0.2]
    @test swapcols!(copy(a), 2, 4) ≈ [1, 5, 3, 2]
    @test swapcols!(copy(a), 2, 4, 0.1, 0.2) ≈ [1, 1, 3, 0.2]
    @test swaprows!(copy(A), 2, 4) ≈ [1 5; 4 8; 3 7; 2 6]
    @test swaprows!(copy(A), 2, 4, 0.1, 0.2) ≈ [1 5; 0.8 1.6; 3 7; 0.2 0.6]
    @test swapcols!(copy(A), 2, 1) ≈ [5 1; 6 2; 7 3; 8 4]
    @test swapcols!(copy(A), 2, 1, 0.1, 0.2) ≈ [0.5 0.2; 0.6 0.4; 0.7 0.6; 0.8 0.8]

    @test mulrow!(copy(a), 2, 0.1) ≈ [1, 0.2, 3, 5]
    @test mulcol!(copy(a), 2, 0.1) ≈ [1, 0.2, 3, 5]
    @test mulrow!(copy(A), 2, 0.1) ≈ [1 5; 0.2 0.6; 3 7; 4 8]
    @test mulcol!(copy(A), 2, 0.1) ≈ [1 0.5; 2 0.6; 3 0.7; 4 0.8]
end

@testset "u1rows! & unrows!" begin
    for v in [randn(ComplexF64, 1 << 6), randn(ComplexF64, 1 << 6, 3)]
        u1 = randn(ComplexF64, 2, 2)
        su1 = SMatrix{2,2}(u1)
        inds1 = [1, 3]
        sinds1 = SVector{2}(inds1)
        @test 0 == @allocated unrows!(v, sinds1, su1)

        unrows!(v, sinds1, su1)
        @test u1rows!(copy(v), inds1..., u1[1], u1[3], u1[2], u1[4]) ≈
              unrows!(copy(v), inds1, u1)
        @test unrows!(copy(v), inds1, u1) ≈ unrows!(copy(v), sinds1, su1)
    end
end


@testset "dense unrows!" begin
    v = randn(ComplexF64, 1 << 6, 2)
    inds = [1, 3, 8, 2]
    A = rand(ComplexF64, 4, 4)
    sinds = SVector{4}(inds)
    sA = SMatrix{4,4}(A)
    unrows!(v, sinds, sA)
    @test 0 == @allocated unrows!(v, sinds, sA)
    out = zeros(ComplexF64, 4, 4)
    @test unrows!(copy(v), sinds, sA)[:, 1] ≈ unrows!(copy(v[:, 1]), inds, A)
end

@testset "diagonal unrows!" begin
    v = randn(ComplexF64, 1 << 6)
    dg = ComplexF64[1 0; 0 -1] |> staticize
    inds = SVector{2}([1, 3])
    unrows!(v, inds, dg)
    # NOTE: some machines have a small allocation
    @test 32 >= @allocated unrows!(v, inds, dg)
    @test unrows!(copy(v), inds, dg) ≈ unrows!(copy(v), [1, 3], dg)
    @test unrows!(copy(v), inds, IMatrix{1 << 2}()) == v
end

@testset "permmatrix unrows!" begin
    N, M = 6, 2
    v = randn(ComplexF64, 1 << N)
    pm = pmrand(ComplexF64, 1 << M)
    inds = [1, 3, 8, 2]
    sinds = SVector{1 << M}(inds)
    spm = pm |> staticize
    unrows!(v, inds, spm)
    @test unrows!(copy(v), sinds, spm) ≈ unrows!(copy(v), inds, pm |> Matrix)
end

@testset "csc unrows!" begin
    v = randn(ComplexF64, 1 << 6)
    inds = [1, 3, 8, 2]
    A = sprand(ComplexF64, 4, 4, 0.5)
    work = zeros(ComplexF64, 4)
    sinds = SVector{4}(inds)
    sA = A |> staticize
    unrows!(v, sinds, sA, work)
    # TODO: this use views?
    # @test 0 == @allocated unrows!(v, sinds, sA, work)
    @test unrows!(copy(v), sinds, sA, work) ≈ unrows!(copy(v), inds, A |> Matrix)
end

@testset "batch normalize" begin
    s = rand(3, 4)
    batch_normalize!(s, 1)
    for i = 1:4
        @test sum(s[:, i]) ≈ 1
    end

    s = rand(3, 4)
    ss = batch_normalize(s, 1)
    for i = 1:4
        @test sum(s[:, i]) != 1
        @test sum(ss[:, i]) ≈ 1
    end
end

@testset "hilbertkron" begin
    A, B, C, D = [randn(2, 2) for i = 1:4]
    II = IMatrix(2)
    ⊗ = kron
    @test hilbertkron(4, [A, B], [3, 1]) ≈ II ⊗ A ⊗ II ⊗ B
    @test hilbertkron(4, [A ⊗ B, C], [3, 1]) ≈ A ⊗ B ⊗ II ⊗ C
    @test hilbertkron(4, [A ⊗ B], [1]) ≈ II ⊗ II ⊗ A ⊗ B
    @test hilbertkron(4, [A ⊗ B, C ⊗ D], [1, 3]) ≈ C ⊗ D ⊗ A ⊗ B

    U = randn(2, 2)
    U2 = randn(4, 4)
    m = U2 ⊗ II ⊗ U ⊗ II
    @test m == hilbertkron(5, [U, U2], [2, 4])
end

@testset "batched kron" begin
    A, B, C =
        rand(ComplexF64, 4, 4, 3), rand(ComplexF64, 4, 4, 3), rand(ComplexF64, 4, 4, 3)
    D = batched_kron(A, B, C)

    tD = zeros(ComplexF64, 64, 64, 3)
    for k = 1:3
        tD[:, :, k] = kron(A[:, :, k], B[:, :, k], C[:, :, k])
    end

    @test tD ≈ D

    B2 = reshape(transpose(reshape(permutedims(B, (3, 1, 2)), 3, 16)), 4, 4, 3)
    @test B2 isa Base.ReshapedArray
    @test Array(B2) ≈ B
    D2 = batched_kron(A, B2, C)
    @test tD ≈ D2
end

@testset "rotmat" begin
    theta = 0.5
    @test rot_mat(ComplexF64, Const.X, theta) ≈ ComplexF64[
        cos(theta / 2) -im*sin(theta / 2)
        -im*sin(theta / 2) cos(theta / 2)
    ]
    @test rot_mat(ComplexF64, Const.X, theta) |> eltype == ComplexF64
    @test rot_mat(ComplexF32, Const.X, theta) |> eltype == ComplexF32
end

using LuxurySparse: pmrand
@testset "reorder" begin
    ⊗ = kron
    PA = pmrand(2)
    PB = pmrand(2)
    PC = pmrand(2)
    @test reorder(PC ⊗ PB ⊗ PA, [3, 1, 2]) ≈ PB ⊗ PA ⊗ PC
    @test invorder(PC ⊗ PB ⊗ PA) ≈ PA ⊗ PB ⊗ PC
end

@testset "logdi" begin
    @test logdi(9, 3) == 2
    @test_throws ArgumentError logdi(9, 5)
end

@testset "matchtype" begin
    @test YaoArrayRegister.matchtype(ComplexF64, randn(2,2)) isa Array{ComplexF64}
    @test YaoArrayRegister.matchtype(ComplexF64, randn(ComplexF64, 2,2)) isa Array{ComplexF64}
end