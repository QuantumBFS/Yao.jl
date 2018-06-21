using Compat
using Compat.Test
using Yao
using Yao.Blocks
using Yao.Intrinsics
using Yao.Boost
using Yao.LuxurySparse

####################### Controlled Gates #######################
p0 = mat(P0)
p1 = mat(P1)
gate_list = [X, Y, Z, H]

num_bit = 6
@testset "Single Qubit" begin
    for gg in gate_list
        @test mat(kron(num_bit, 3=>gg)) ≈ hilbertkron(num_bit, [mat(gg)], [3])
    end
end

@testset "Single Control Gates" begin
    for gg in gate_list
        @test mat(control(num_bit, (4,), 3=>gg)) == general_controlled_gates(num_bit, [p1], [4],  [mat(gg)], [3])
    end
end

@testset "Multiple Control Gates" begin
    for gg in gate_list
        @test mat(control(6, (4,2), 3=>gg)) == general_controlled_gates(num_bit, [p1, p1], [4,2],  [mat(gg)], [3])
    end
end

@testset "Rotation Gates" begin
    for gg in gate_list
        @test mat(kron(num_bit, 3=>rot(gg, π/8))) ≈ hilbertkron(num_bit, [rotmat(mat(gg), π/8)], [3])
    end
end

@testset "Single-Controlled Rotation Gates" begin
    for gg in gate_list
        @test mat(control(num_bit, (4,), 3=>rot(gg, π/8))) ≈ general_controlled_gates(num_bit, [p1], [4], [rotmat(mat(gg), π/8)], [3])
    end
end

@testset "Multi-Controlled Rotation Gates" begin
    for gg in gate_list
        @test mat(control(num_bit, (4,2), 3=>rot(gg, π/8))) ≈ general_controlled_gates(num_bit, [p1, p1], [4, 2], [rotmat(mat(gg), π/8)], [3])
    end
end
