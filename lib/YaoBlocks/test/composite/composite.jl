using Test, YaoBase, YaoBlocks, YaoArrayRegister

@testset "test chain" begin
    include("chain.jl")
end

@testset "test kron" begin
    include("kron.jl")
end

@testset "test control" begin
    include("control.jl")
end

@testset "test put" begin
    include("put.jl")
end

@testset "test repeated" begin
    include("repeated.jl")
end

@testset "test subroutine" begin
    include("subroutine.jl")
end

@testset "test tag" begin
    include("tag.jl")
    include("cache.jl")
end

@testset "test unitary channel" begin
    include("unitary_channel.jl")
end

@testset "test single block chsubblocks" begin
    @test chsubblocks(chain(X), Y) == chain(Y)
    @test chsubblocks(kron(X), Y) == kron(Y)
    @test chsubblocks(*(X), Y) == *(Y)
    @test chsubblocks(+(X), Y) == +(Y)
end

# check extension fallback errors
struct MockedQFT{N,D} <: CompositeBlock{N,D} end
@test_throws MethodError ishermitian(MockedQFT{2,2}())
@test_throws MethodError isunitary(MockedQFT{2,2}())
