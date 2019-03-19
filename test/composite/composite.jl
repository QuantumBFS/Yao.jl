using Test, YaoBlockTree

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

@testset "test roll" begin
    include("roller.jl")
end

@testset "test concentrate" begin
    include("concentrator.jl")
end

@testset "test cache" begin
    include("cache.jl")
end
