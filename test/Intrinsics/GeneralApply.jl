using Test, Random, LinearAlgebra, SparseArrays

using StaticArrays: SVector, SMatrix
using Yao
using Yao.Intrinsics
using Yao.Intrinsics: u1rows!, unrows!, u1apply!, unapply!, cunapply!
using Yao.Blocks: P0, P1

@testset "u1apply! and unapply" begin
    ⊗ = kron
    u1 = randn(ComplexF64, 2, 2)
    v = randn(ComplexF64, 1<<4)
    II = eye(2)

    @test u1apply!(copy(v), u1, 3) ≈ (II ⊗ u1 ⊗ II ⊗ II)*v ≈ u1apply!(reshape(copy(v), :,1), u1, 3)
    @test unapply!(copy(v), u1, (3,)) == u1apply!(copy(v), u1, 3)
    @test unapply!(copy(v), kron(u1, u1), (3, 1)) ≈ u1apply!(u1apply!(copy(v), u1, 3), u1, 1)
    @test unapply!(reshape(copy(v), :,1), kron(u1, u1), (3, 1)) ≈ u1apply!(u1apply!(reshape(copy(v),:,1), u1, 3), u1, 1)
end

@testset "general control" begin
    v = randn(ComplexF64, 1<<5)
    u1 = randn(ComplexF64, 2,2)
    @test cunapply!(copy(v), (1,), (1,), u1, (3,)) ≈ general_controlled_gates(5, [mat(P1)], [1], [u1], [3]) * v
    @test cunapply!(copy(v), (1,), (0,), u1, (3,)) ≈ general_controlled_gates(5, [mat(P0)], [1], [u1], [3]) * v

    # control U2
    u2 = kron(u1, u1)
    @test cunapply!(copy(v), (1,), (1,), u2, (3,4)) ≈ general_controlled_gates(5, [mat(P1)], [1], [u2], [3]) * v

    # multi-control U2
    @test cunapply!(copy(v), (5, 1), (1, 0), u2, (3,4)) ≈ general_controlled_gates(5, [mat(P1), mat(P0)], [5, 1], [u2], [3]) * v
end
