using Test, YaoBlocks

@testset "utils" begin
    include("utils.jl")
end

@testset "error" begin
    include("error.jl")
end

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

@testset "test block tools" begin
    include("blocktools.jl")
end

@testset "Yao/#166" begin
    @test_throws ErrorException put(100, 1 => X) |> mat
end

@testset "dispatch" begin
    g = dispatch!(chain(Rx(0.1), Rx(0.2)), [0.3, 0])
    @test getiparams(g[1]) == 0.3
    @test getiparams(g[2]) == 0.0

    g = dispatch(chain(Rx(0.1), Rx(0.2)), [0.0f3, 0.0f0])
    @test getiparams(g[1]) === 0.0f3
    @test getiparams(g[2]) === 0.0f0
end

@testset "abstract blocks" begin
    include("abstract_blocks.jl")
end

@testset "extending reg blocks" begin
    include("extending_reg.jl")
end

@testset "measure_ops" begin
    include("measure_ops.jl")
end

@testset "test tree utils" begin
    include("treeutils/treeutils.jl")
end

@testset "autodiff" begin
    include("autodiff/autodiff.jl")
end
