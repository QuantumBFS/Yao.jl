using Test, Random, LinearAlgebra, SparseArrays


@testset "primitives" begin
include("Primitive.jl")
end

@testset "composites" begin
include("Composite.jl")
end

@testset "container" begin
include("Container.jl")
end
