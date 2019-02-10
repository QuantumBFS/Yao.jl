using Test, Random, LinearAlgebra, SparseArrays


@testset "core APIs" begin
    include("Core.jl")
end

@testset "matrix block" begin
    include("MatrixBlock.jl")
end

@testset "measure" begin
    include("Measure.jl")
end

@testset "function" begin
    include("Function.jl")
end

@testset "sequential" begin
    include("Sequential.jl")
end

@testset "blockoperations" begin
    include("blockoperations.jl")
end

@testset "arithmatics" begin
    include("linalg.jl")
end

@testset "pauligroup" begin
    include("pauligroup.jl")
end
