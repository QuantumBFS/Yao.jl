using YaoToEinsum, Test

@testset "circuitmap" begin
    include("circuitmap.jl")
end

@testset "densitymatrix" begin
    include("densitymatrix.jl")
end