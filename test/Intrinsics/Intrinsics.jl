using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

@testset "math utils" begin
include("Math.jl")
end

@testset "basis" begin
include("Basis.jl")
end
