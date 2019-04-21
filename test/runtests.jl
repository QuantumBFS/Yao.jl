using Test, YaoBlocks

@testset "test primitive block" begin
    include("primitive/primitive.jl")
end

@testset "test composite block" begin
    include("composite/composite.jl")
end

@testset "test symbolic algebra" begin
    include("algebra.jl")
end

@testset "test layouts" begin
    include("layouts.jl")
end

@testset "test matrix manipulation routines" begin
    include("rountines.jl")
end

@testset "Yao/#166" begin
    @test_throws ErrorException put(100, 1=>X) |> mat
end

# TODO
# @testset "test demos" begin
#     include("algo/qft.jl")
# end
