using Test, Random, LinearAlgebra, SparseArrays
using Yao
using YaoExtensions
using QuAlgorithmZoo

@testset "PhaseEstimation" begin
    include("PhaseEstimation.jl")
end

@testset "hamiltonian solvers" begin
    include("hamiltonian_solvers.jl")
end

@testset "hadamard test" begin
    include("HadamardTest.jl")
end

@testset "QSVD" begin
    include("QSVD.jl")
end
