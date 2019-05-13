using Test, YaoBlocks

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

@testset "test concentrate" begin
    include("concentrator.jl")
end

@testset "test tag" begin
    include("tag.jl")
    include("cache.jl")    
end

@testset "test pauli string" begin
    include("pauli_string.jl")
end

@testset "test single block chsubblocks" begin
    @test chsubblocks(chain(X), Y) == chain(Y)
    @test chsubblocks(kron(X), Y) == kron(Y)
    @test chsubblocks(prod(X), Y) == prod(Y)
    @test chsubblocks(sum(X), Y) == sum(Y)
end
