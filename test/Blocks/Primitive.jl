using Compat.Test

@testset "Constant Gates" begin
    include("ConstantGate.jl")
end

@testset "Phase Gate" begin
    include("PhaseGate.jl")
end

@testset "Rotation Gate" begin
    include("RotationGate.jl")
end
