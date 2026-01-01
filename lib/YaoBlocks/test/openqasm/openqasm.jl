using Test, YaoBlocks, YaoBlocks.ConstGate

@testset "compile" begin
    include("compile.jl")
end

@testset "parse" begin
    include("parse.jl")
end
