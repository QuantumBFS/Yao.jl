using Test

@testset "RotBasis" begin
    include("RotBasis.jl")
end

@testset "Sequence" begin
    include("Sequence.jl")
end

@testset "Bag" begin
    include("Bag.jl")
end

@testset "TrivialGate" begin
    include("TrivialGate.jl")
end

@testset "ConditionBlock" begin
    include("ConditionBlock.jl")
end

@testset "Mod" begin
    include("Mod.jl")
end

@testset "pauli_strings" begin
    include("pauli_strings.jl")
end

@testset "reflect_gate" begin
    include("reflect_gate.jl")
end

@testset "math_gate" begin
    include("math_gate.jl")
end

@testset "shortcuts" begin
    include("shortcuts.jl")
end
