using Test, Random, LinearAlgebra, SparseArrays

@testset "chain block" begin
    include("ChainBlock.jl")
end

@testset "kron block" begin
    include("KronBlock.jl")
end

@testset "roller block" begin
    include("Roller.jl")
end

using Yao
using Yao.Blocks

@testset "map" begin
    dst = ChainBlock(put(5, 1=>X), put(5, 2=>Y), put(5, 1=>Z))
    @test_throws MethodError KronBlock{5}(X, Y, Z)
    src = KronBlock(X, Y, Z)
    map!(x->kron(5, 1=>Z), dst, subblocks(src))

    for each in dst
        @test isa(each, KronBlock)
    end
end

@testset "nparameters" begin
    @test nparameters(ChainBlock(X, Y, Z)) == 0
    @test nparameters(ChainBlock(phase(0.1), X, phase(0.2))) == 2
    @test nparameters(KronBlock{5}(1=>X, 4=>rot(X, 0.2))) == 1

    @test collect(parameters(ChainBlock(phase(0.1), shift(0.2)))) ≈ [0.1, 0.2]
    @test collect(parameters(ChainBlock(kron(4, 1=>phase(0.1), 3=>rot(X, 0.2))))) ≈ [0.1, 0.2]
end

@testset "dispatch" begin
    g = ChainBlock(phase(0.1), phase(0.2), phase(0.3))
    params = rand(3)
    dispatch!(g, params)

    for (each, p) in zip(subblocks(g), params)
        @test each.theta == p
    end

    dispatch!(+, g, [1, 1, 1])
    for (each, p) in zip(subblocks(g), params)
        @test each.theta == p + 1
    end

    # block with different size
    g = KronBlock{3}(1=>phase(0.1), 3=>ChainBlock(phase(0.2), phase(0.3)))
    dispatch!(g, [1, 2, 3])
    @test g[1].theta == 1
    @test g[3][1].theta == 2
    @test g[3][2].theta == 3

    g = KronBlock{5}(1=>phase(0.1), 3=>X, 5=>ChainBlock(phase(0.2), phase(0.3)))
    dispatch!(g, [1, 2, 3])
    @test g[1].theta == 1
    @test g[5][1].theta == 2
    @test g[5][2].theta == 3
end
