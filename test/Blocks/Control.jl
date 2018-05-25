using Compat.Test
using QuCircuit
import QuCircuit: ControlBlock
import QuCircuit: _single_control_gate_sparse,
                  _single_inverse_control_gate_sparse,
                  A_kron_B, ControlQuBit, PhiGate
import QuCircuit: CONST_SPARSE_P0, CONST_SPARSE_P1

@testset "getindex & setindex" begin
g = ControlBlock{4}([1, 2], phase(0.1), 4)
@test isa(g[1], ControlQuBit)
@test isa(g[4], PhiGate)
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
    @test nqubit(g) == 2
    mat = eye(U) ⊗ CONST_SPARSE_P0() + U ⊗ CONST_SPARSE_P1()
    @test sparse(g) == mat
end

@testset "single control with inferred size" begin
    g = ControlBlock([2, ], X(), 3)
    @test nqubit(g) == 3
    mat =  (eye(U) ⊗ CONST_SPARSE_P0() + U ⊗ CONST_SPARSE_P1()) ⊗ Id
    @test sparse(g) == mat
end

@testset "control with fixed size" begin
    g = ControlBlock{4}([2, ], X(), 3)
    @test nqubit(g) == 4
    mat = Id ⊗ (eye(U) ⊗ CONST_SPARSE_P0() + U ⊗ CONST_SPARSE_P1()) ⊗ Id
    @test sparse(g) == mat
end

@testset "control with blank" begin
    g = ControlBlock{4}([3, ], X(), 2)
    @test nqubit(g) == 4

    mat = Id ⊗ (CONST_SPARSE_P0() ⊗ eye(U) + CONST_SPARSE_P1() ⊗ U) ⊗ Id
    @test sparse(g) == mat
end

@testset "multi control" begin
    g = ControlBlock([2, 3], X(), 4)
    @test nqubit(g) == 4

    op = eye(U) ⊗ CONST_SPARSE_P0() +  U ⊗ CONST_SPARSE_P1()
    op = eye(op) ⊗ CONST_SPARSE_P0() + op ⊗ CONST_SPARSE_P1()
    op = op ⊗ Id
    @test sparse(g) == op
end

@testset "multi control with blank" begin
    g = ControlBlock{7}([6, 4, 2], X(), 3) # -> [2, 4, 6]
    @test nqubit(g) == 7

    op = eye(U) ⊗ CONST_SPARSE_P0() + U ⊗ CONST_SPARSE_P1() # 2, 3
    op = CONST_SPARSE_P0() ⊗ eye(op) + CONST_SPARSE_P1() ⊗ op # 2, 3, 4
    op = CONST_SPARSE_P0() ⊗ Id ⊗ eye(op) + CONST_SPARSE_P1() ⊗ Id ⊗ op # 2, 3, 4, blank, 6
    op = op ⊗ Id # blank, 2, 3, blank, 4, 6
    op = Id ⊗ op # blnak, 2, 3, blank, 4, 6, blank

    @test sparse(g) == op
end

@testset "inverse control" begin
    g = ControlBlock{2}([-1, ], X(), 2)

    op = U ⊗ CONST_SPARSE_P0() + eye(U) ⊗ CONST_SPARSE_P1()
    @test sparse(g) == op
end

end # control matrix form
