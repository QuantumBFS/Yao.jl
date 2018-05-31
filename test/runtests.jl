using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

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

@testset "interface" begin
    include("Interfaces/Interfaces.jl")
end

# @testset "show" begin
# include("show.jl")
# end
