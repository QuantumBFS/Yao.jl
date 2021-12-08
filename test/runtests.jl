using YaoPlots, ZXCalculus
using Test

@testset "helperblock" begin
    include("helperblock.jl")
end

@testset "vizcircuit" begin
    include("vizcircuit.jl")
end

@testset "zx_plot" begin
    include("zx_plot.jl")
end
