using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays


@testset "primitives" begin
include("Primitive.jl")
end

@testset "composites" begin
include("Composite.jl")
end
