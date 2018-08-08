using Test, Random, LinearAlgebra, SparseArrays


using Yao
using QuAlgorithmZoo


@testset "QFT" begin
    include("QFT.jl")
end

@testset "Differential" begin
    include("Differential.jl")
end

@testset "RotBasis" begin
    include("RotBasis.jl")
end

@testset "Grover" begin
    include("Grover.jl")
end
