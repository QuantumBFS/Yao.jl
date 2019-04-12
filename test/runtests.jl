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

@testset "test demos" begin
    include("algo/qft.jl")
end
