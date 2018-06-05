using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays


@testset "Constant Gates" begin
    include("ConstantGate.jl")
end

@testset "Phase Gate" begin
    include("PhaseGate.jl")
end

@testset "Rotation Gate" begin
    include("RotationGate.jl")
end

@testset "Swap Gate" begin
    include("SwapGate.jl")
end
