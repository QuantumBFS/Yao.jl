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
