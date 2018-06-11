using Compat.Test
using Yao
using Yao.Intrinsics
using Yao.Blocks
using Yao.Boost

@testset "Single Control" begin
    cb = ControlBlock{2}((2,), X, 1)
    @test mat(cb) ≈ mat(CNOT)

    for G in [X, Y, Z, H]
        cb = ControlBlock{4}((2,), G, 4)
        @test mat(cb) ≈ general_controlled_gates(4, [mat(P1)], [2], [mat(G)], [4])
        cb = ControlBlock{4}((2,), (0,), G, 4)
        @test mat(cb) ≈ general_controlled_gates(4, [mat(P0)], [2], [mat(G)], [4])
    end
end

@testset "Multiple Control" begin
    mcb = ControlBlock{3}((3, 2), X, 1)
    @test mat(mcb) ≈ mat(Toffoli)
    for G in [X, Y, Z, H]
        cb = ControlBlock{6}((2, 5, 1), (1, 0, 0), G, 3)
        @test mat(cb) ≈ general_controlled_gates(6, [mat(P1), mat(P0), mat(P0)], [2, 5, 1], [mat(G)], [3])
        cb = ControlBlock{5}((5, 1), (1, 1), G, 3)
        @test mat(cb) ≈ general_controlled_gates(5, [mat(P1), mat(P1)], [5, 1], [mat(G)], [3])
    end
end
