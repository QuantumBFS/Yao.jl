using Test, YaoBlockTree

@testset "test constant gates" begin
    include("const_gate.jl")
end

@testset "test phase gate" begin
    include("phase_gate.jl")
end

@testset "test shift gate" begin
    include("shift_gate.jl")
end
