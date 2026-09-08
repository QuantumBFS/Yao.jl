using YaoPlots
using Test
using Aqua

Aqua.test_all(YaoPlots)

@testset "helperblock" begin
    include("helperblock.jl")
end

@testset "vizcircuit" begin
    include("vizcircuit.jl")
end

@testset "bloch" begin
    include("bloch.jl")
end
