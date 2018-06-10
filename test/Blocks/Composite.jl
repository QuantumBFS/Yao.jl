using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

@testset "chain block" begin
    include("ChainBlock.jl")
end

@testset "kron block" begin
    include("KronBlock.jl")
end

@testset "control block" begin
    include("Control.jl")
end

@testset "roller block" begin
    include("Roller.jl")
end

using Yao
using Yao.Blocks

@testset "map" begin
    dst = ChainBlock(X(), Y(), Z())
    src = KronBlock{5}(X(), Y(), Z())
    map!(x->kron(2, Z()), dst, blocks(src))

    for each in dst
        @test isa(each, KronBlock)
    end
end

@testset "nparameters" begin
    @test nparameters(ChainBlock(X(), Y(), Z())) == 0
    @test nparameters(ChainBlock(phase(0.1), X(), phase(0.2))) == 2
    @test nparameters(KronBlock{5}(1=>X(), 4=>rot(X, 0.2))) == 1
    @test nparameters(ControlBlock{5}([1, 2], phase(0.1), 4)) == 1
end

@testset "parameters" begin
@test parameters(ChainBlock(phase(0.1), shift(0.2))) ≈ [0.1, 0.2]
@test parameters(ChainBlock(kron(4, 1=>phase(0.1), 3=>rot(X, 0.2)))) ≈ [0.1, 0.2]
@test parameters(ControlBlock{5}([1, 2], phase(0.1), 4)) ≈ [0.1]
@test parameters(KronBlock{5}(1=>X, 4=>rot(X, 0.2))) ≈ [0.2]
end


@testset "dispatch" begin
    g = ChainBlock(phase(0.1), phase(0.2), phase(0.3))
    dispatch!(g, [1, 2, 3])
    @test g[1].theta == 1
    @test g[2].theta == 2
    @test g[3].theta == 3

    dispatch!(+, g, [1, 1, 1])
    @test g[1].theta == 2
    @test g[2].theta == 3
    @test g[3].theta == 4

    # block with different size
    g = KronBlock{3}(1=>phase(0.1), 3=>ChainBlock(phase(0.2), phase(0.3)))
    dispatch!(g, [1, 2, 3])
    @test g[1].theta == 1
    @test g[3][1].theta == 2
    @test g[3][2].theta == 3

    # direct dispatch
    g = KronBlock{5}(1=>phase(0.1), 3=>X(), 5=>ChainBlock(phase(0.2), phase(0.3)))
    dispatch!(g, 1, [2, 3])
    @test g[1].theta == 1
    @test g[5][1].theta == 2
    @test g[5][2].theta == 3
end
