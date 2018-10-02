using Test, Random, LinearAlgebra, SparseArrays

@testset "control block" begin
    include("Control.jl")
end

@testset "repeat block" begin
    include("Repeated.jl")
end

@testset "concentrator" begin
    include("Concentrator.jl")
end

@testset "putblock" begin
    include("PutBlock.jl")
end

@testset "tagblock" begin
    include("TagBlock.jl")
end

using Yao
using Yao.Blocks

@testset "nparameters" begin
    @test nparameters(ControlBlock{5}((1, 2), phase(0.1), (4,))) == 1
    @test collect(parameters(ControlBlock{5}((1, 2), phase(0.1), (4, )))) ≈ [0.1]
end

@testset "dispatch" begin
    g = chain(control(5, 2, 3=>Rx(0.3)), put(5, 1=>Ry(0.6)))
    params = [-0.2, 0.4]
    dispatch!(g, params)
    @test g[1].theta == -0.2
    @test g[2].theta == 0.4

    dispatch!(+, g, [1, 1])
    @test g[1].theta == 0.8
    @test g[2].theta == 1.4
end
