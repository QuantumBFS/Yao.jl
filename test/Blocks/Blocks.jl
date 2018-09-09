using Test, Random, LinearAlgebra, SparseArrays


@testset "core APIs" begin
    include("Core.jl")
end

@testset "matrix block" begin
include("MatrixBlock.jl")
end

@testset "concentrator" begin
include("Concentrator.jl")
end

@testset "cache" begin
include("CacheFragment.jl")
include("CachedBlock.jl")
end

@testset "daggered" begin
include("Daggered.jl")
end

@testset "scale" begin
include("Scale.jl")
end

@testset "putblock" begin
include("PutBlock.jl")
end

@testset "measure" begin
include("Measure.jl")
end

@testset "function" begin
include("Function.jl")
end

@testset "sequential" begin
include("Sequential.jl")
end

@testset "blockoperations" begin
include("blockoperations.jl")
end
