using Test, Random, LinearAlgebra, SparseArrays
using Yao
using QuAlgorithmZoo


@testset "QFT" begin
    include("QFT.jl")
end

@testset "CircuitBuild" begin
    include("CircuitBuild.jl")
end

@testset "RotBasis" begin
    include("RotBasis.jl")
end

@testset "Grover" begin
    include("Grover.jl")
end

@testset "PhaseEstimation" begin
    include("PhaseEstimation.jl")
end

@testset "HHL" begin
    include("HHL.jl")
end
@testset "diff Eq" begin
    include("lin_diffEq_test.jl")
end

@testset "QCOptProblem" begin
    include("QCOptProblem.jl")
end

@testset "hamiltonian solvers" begin
    include("hamiltonian_solvers.jl")
end

@testset "hadamard test" begin
    include("HadamardTest.jl")
end

@testset "Sequence" begin
    include("Sequence.jl")
end

@testset "Diff" begin
    include("Diff.jl")
end
