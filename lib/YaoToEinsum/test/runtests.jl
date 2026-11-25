using YaoToEinsum, Test
using Aqua

Aqua.test_all(YaoToEinsum)

@testset "circuitmap" begin
    include("circuitmap.jl")
end

@testset "densitymatrix" begin
    include("densitymatrix.jl")
end

@testset "fileio" begin
    include("fileio.jl")
end

@testset "LuxorExt" begin
    include("LuxorExt.jl")
end
