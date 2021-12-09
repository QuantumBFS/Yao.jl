using Test, Yao.EasyBuild

@testset "RotBasis" begin
    include("RotBasis.jl")
end

@testset "Bag" begin
    include("Bag.jl")
end

@testset "EchoBlock" begin
    include("EchoBlock.jl")
end

@testset "ConditionBlock" begin
    include("ConditionBlock.jl")
end

@testset "pauli_strings" begin
    include("pauli_strings.jl")
end

@testset "reflect_gate" begin
    include("reflect_gate.jl")
end

@testset "shortcuts" begin
    include("shortcuts.jl")
end
