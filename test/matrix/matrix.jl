using Test, YaoBlockTree

@testset "test primitive block" begin
    include("primitive/primitive.jl")
end

@testset "test composite block" begin
    include("composite/composite.jl")
end
