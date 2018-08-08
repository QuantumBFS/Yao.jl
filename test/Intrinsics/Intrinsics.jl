using Test, Random, LinearAlgebra, SparseArrays

@testset "math utils" begin
include("Math.jl")
end

@testset "basis" begin
include("Basis.jl")
end

@testset "macro tools" begin
include("MacroTools.jl")
end

@testset "tuple tools" begin
include("TupleTools.jl")
end

@testset "reorder" begin
include("reorder.jl")
end
