using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

@testset "utils" begin
include("Intrinsics/Intrinsics.jl")
end

@testset "luxury sparse" begin
include("LuxurySparse/LuxurySparse.jl")
end

@testset "register" begin
include("Register.jl")
end

@testset "blocks" begin
include("Blocks/Blocks.jl")
end

#@testset "cache" begin
#include("Cache/Cache.jl")
#end

#@testset "interface" begin
#    include("Interfaces/Interfaces.jl")
#end

# @testset "show" begin
# include("show.jl")
# end
