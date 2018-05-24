using Compat.Test

@testset "primitives" begin
include("Primitive.jl")
end

@testset "composites" begin
include("Composite.jl")
end
