using Compat
using Compat.Test
using Yao
using Yao.Blocks
using Yao.Intrinsics
using Yao.Boost
using Yao.LuxurySparse

####################### Controlled Gates #######################
rotgate(gate::AbstractMatrix, θ::Real) = expm(-0.5im*θ*Matrix(gate))

p0 = mat(P0)
p1 = mat(P1)
gate_list = [X, Y, Z, H]

num_bit = 6
@testset "Single Qubit" begin
    for gg in gate_list
        @test mat(KronBlock{num_bit, ComplexF64}([3], [gg])) ≈ hilbertkron(num_bit, [mat(gg)], [3])
    end
end

@testset "Single Control Gates" begin
    for gg in gate_list
        @test mat(ControlBlock{6}([4], gg, 3)) == general_controlled_gates(num_bit, [p1], [4],  [mat(gg)], [3])
    end
end

@testset "Multiple Control Gates" begin
    for gg in gate_list
        @test mat(ControlBlock{6}([4,2], gg, 3)) == general_controlled_gates(num_bit, [p1, p1], [4,2],  [mat(gg)], [3])
    end
end

@testset "Rotation Gates" begin
    for gg in gate_list
        @test mat(KronBlock{num_bit, ComplexF64}([3], [RotationGate(gg, π/8)])) ≈ hilbertkron(num_bit, [rotgate(mat(gg), π/8)], [3])
    end
end

@testset "Single-Controlled Rotation Gates" begin
    for gg in gate_list
        @test mat(ControlBlock{num_bit}([4], RotationGate(gg, π/8), 3)) ≈ general_controlled_gates(num_bit, [p1], [4], [rotgate(mat(gg), π/8)], [3])
    end
end

@testset "Multi-Controlled Rotation Gates" begin
    for gg in gate_list
        @test mat(ControlBlock{num_bit}([4,2], RotationGate(gg, π/8), 3)) ≈ general_controlled_gates(num_bit, [p1, p1], [4, 2], [rotgate(mat(gg), π/8)], [3])
    end
end
