using Compat.Test
using Yao
import Yao: ControlBlock
import Yao: _single_control_gate_sparse,
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
U = sparse(X())
Id = speye(Compat.ComplexF64, 2)

@testset "single control" begin
    g = ControlBlock([1, ], X(), 2)
    @test nqubits(g) == 2
    mat = eye(U) ⊗ Const.Sparse.P0() + U ⊗ Const.Sparse.P1()
    @test sparse(g) == mat
end

@testset "single control with inferred size" begin
    g = ControlBlock([2, ], X(), 3)
    @test nqubits(g) == 3
    mat =  (eye(U) ⊗ Const.Sparse.P0() + U ⊗ Const.Sparse.P1()) ⊗ Id
    @test sparse(g) == mat
end

@testset "control with fixed size" begin
    g = ControlBlock{4}([2, ], X(), 3)
    @test nqubits(g) == 4
    mat = Id ⊗ (eye(U) ⊗ Const.Sparse.P0() + U ⊗ Const.Sparse.P1()) ⊗ Id
    @test sparse(g) == mat
end

@testset "control with blank" begin
    g = ControlBlock{4}([3, ], X(), 2)
    @test nqubits(g) == 4

    mat = Id ⊗ (Const.Sparse.P0() ⊗ eye(U) + Const.Sparse.P1() ⊗ U) ⊗ Id
    @test sparse(g) == mat
end

@testset "multi control" begin
    g = ControlBlock([2, 3], X(), 4)
    @test nqubits(g) == 4

    op = eye(U) ⊗ Const.Sparse.P0() +  U ⊗ Const.Sparse.P1()
    op = eye(op) ⊗ Const.Sparse.P0() + op ⊗ Const.Sparse.P1()
    op = op ⊗ Id
    @test sparse(g) == op
end

@testset "multi control with blank" begin
    g = ControlBlock{7}([6, 4, 2], X(), 3) # -> [2, 4, 6]
    @test nqubits(g) == 7

    op = eye(U) ⊗ Const.Sparse.P0() + U ⊗ Const.Sparse.P1() # 2, 3
    op = Const.Sparse.P0() ⊗ eye(op) + Const.Sparse.P1() ⊗ op # 2, 3, 4
    op = Const.Sparse.P0() ⊗ Id ⊗ eye(op) + Const.Sparse.P1() ⊗ Id ⊗ op # 2, 3, 4, blank, 6
    op = op ⊗ Id # blank, 2, 3, blank, 4, 6
    op = Id ⊗ op # blnak, 2, 3, blank, 4, 6, blank

    @test sparse(g) == op
end

@testset "inverse control" begin
    g = ControlBlock{2}([-1, ], X(), 2)

    op = U ⊗ Const.Sparse.P0() + eye(U) ⊗ Const.Sparse.P1()
    @test sparse(g) == op
end

end # control matrix form
