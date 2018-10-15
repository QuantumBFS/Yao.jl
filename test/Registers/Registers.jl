using Test, Random, LinearAlgebra, SparseArrays

@testset "abstract register" begin
    include("AbstractRegister.jl")
end

@testset "default register" begin
    include("Default.jl")
    include("Focus.jl")
end

@testset "reorder" begin
    include("reorder.jl")
end
