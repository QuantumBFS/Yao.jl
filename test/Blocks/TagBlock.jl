using Test
using Yao, Yao.Blocks

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
