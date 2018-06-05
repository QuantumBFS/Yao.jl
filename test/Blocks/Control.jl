using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao
using Yao.Blocks
using Yao.LuxurySparse
import Yao.Blocks: _single_control_gate_sparse,
    _single_inverse_control_gate_sparse,
    A_kron_B, ControlQuBit, PhaseGate
# import Yao: Const.Sparse.P0, Const.Sparse.P1

@testset "getindex & setindex" begin
g = ControlBlock{4}([1, 2], phase(0.1), 4)
@test isa(g[1], ControlQuBit)
@test isa(g[4], PhaseGate)
@test_throws KeyError g[3]
@test_throws BoundsError g[5]
end

@testset "iteration" begin
    g = ControlBlock{4}([1, 2], phase(0.1), 4)
    @test collect(g) == [g.block]
    @test blocks(g) == [g.block]
end

@testset "copy" begin
    g = ControlBlock{4}([1, 2], phase(0.1), 4)
    cg = copy(g)
    cg[4].theta = 0.2
    @test g[4].theta == 0.1
end

@testset "matrix" begin

⊗ = kron
U = mat(X)

@testset "single control" begin
    g = ControlBlock([1, ], X, 2)
    @test nqubits(g) == 2
    m = IMatrix(U) ⊗ mat(P0) + U ⊗ mat(P1)
    @test mat(g) == m
end

@testset "single control with inferred size" begin
    g = ControlBlock([2, ], X, 3)
    @test nqubits(g) == 3
    m =  (IMatrix(U) ⊗ mat(P0) + U ⊗ mat(P1)) ⊗ mat(I2)
    @test mat(g) == m
end

@testset "control with fixed size" begin
    g = ControlBlock{4}([2, ], X, 3)
    @test nqubits(g) == 4
    m = mat(I2) ⊗ (IMatrix(U) ⊗ mat(P0) + U ⊗ mat(P1)) ⊗ mat(I2)
    @test mat(g) == m
end

@testset "control with blank" begin
    g = ControlBlock{4}([3, ], X, 2)
    @test nqubits(g) == 4

    m = mat(I2) ⊗ (mat(P0) ⊗ IMatrix(U) + mat(P1) ⊗ U) ⊗ mat(I2)
    @test mat(g) == m
end

@testset "multi control" begin
    g = ControlBlock([2, 3], X, 4)
    @test nqubits(g) == 4

    op = IMatrix(U) ⊗ mat(P0) +  U ⊗ mat(P1)
    op = IMatrix(op) ⊗ mat(P0) + op ⊗ mat(P1)
    op = op ⊗ mat(I2)
    @test mat(g) == op
end

@testset "multi control with blank" begin
    g = ControlBlock{7}([6, 4, 2], X, 3) # -> [2, 4, 6]
    @test nqubits(g) == 7

    op = IMatrix(U) ⊗ mat(P0) + U ⊗ mat(P1) # 2, 3
    op = mat(P0) ⊗ IMatrix(op) + mat(P1) ⊗ op # 2, 3, 4
    op = mat(P0) ⊗ mat(I2) ⊗ IMatrix(op) + mat(P1) ⊗ mat(I2) ⊗ op # 2, 3, 4, blank, 6
    op = op ⊗ mat(I2) # blank, 2, 3, blank, 4, 6
    op = mat(I2) ⊗ op # blnak, 2, 3, blank, 4, 6, blank

    @test mat(g) == op
end

# FIXME:
# @testset "inverse control" begin
#     g = ControlBlock{2}([-1, ], X, 2)

#     op = U ⊗ mat(P0) + IMatrix(U) ⊗ mat(P1)
#     @test mat(g) ≈ op
# end

end # control matrix form
