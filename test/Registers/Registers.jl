using Test, Random, LinearAlgebra, SparseArrays

@testset "default register" begin
    include("Default.jl")
end
@testset "focus" begin
    include("focus.jl")
end

@testset "measure" begin
    include("measure.jl")
end

@testset "register operations" begin
    include("register_operations.jl")
end

@testset "density matrix" begin
    include("DensityMatrix.jl")
end
