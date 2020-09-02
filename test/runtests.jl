using YaoPlots, ZXCalculus, LightGraphs
using Test

@testset "vizcircuit" begin
    include("vizcircuit.jl")
end

@testset "zx_plot" begin
    include("zx_plot.jl")
end
