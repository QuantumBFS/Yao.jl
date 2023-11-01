using YaoPlots
using Test

@testset "helperblock" begin
    include("helperblock.jl")
end

@testset "vizcircuit" begin
    include("vizcircuit.jl")
end

@testset "bloch" begin
    include("bloch.jl")
end