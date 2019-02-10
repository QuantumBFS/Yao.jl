using Test, Random, LinearAlgebra, SparseArrays

using YaoBase, YaoBlockTree, YaoDenseRegister
using LuxurySparse

@testset "blockfilter expect" begin
    ghz = (product_state(4, 0b0000) + product_state(4, 0b1111)) |> normalize!
    obs1 = kron(4, 2=>Z)
    obs2 = kron(4, 2=>X)
    obs3 = repeat(4, X)
    @test expect(obs1, ghz) ≈ 0
    @test expect(obs2, ghz) ≈ 0
    @test expect(obs3, ghz) ≈ 1

    @test blockfilter(ishermitian, chain(2, kron(2, X, P0), repeat(2, Rx(0), (1,2)), kron(2, 2=>Rz(0.3)))) == [kron(2, X, P0), X, P0, repeat(2, Rx(0), (1,2)), Rx(0)]
    @test blockfilter(b->ishermitian(b) && b isa PrimitiveBlock, chain(2, kron(2, X, P0), repeat(2, Rx(0), (1,2)), kron(2, 2=>Rz(0.3)))) == [X, P0, Rx(0)]
end

@testset "density matrix" begin
    reg = rand_state(4)
    dm = reg |> density_matrix
    op = put(4, 3=>X)
    @test expect(op, dm) ≈ expect(op, reg)

    reg = rand_state(4, 3)
    dm = reg |> density_matrix
    op = put(4, 3=>X)
    @test expect(op, dm) ≈ expect(op, reg)
end

include("linalg.jl")
