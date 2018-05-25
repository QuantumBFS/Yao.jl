using Compat.Test

@testset "utils" begin
include("MathUtils.jl")
end

@testset "register" begin
include("Register.jl")
end

@testset "blocks" begin
include("Blocks/Blocks.jl")
end

@testset "cache" begin
include("Cache/Cache.jl")
end
