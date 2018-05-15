using Compat.Test

import QuCircuit: zero_state, state, focus!,
    X, Y, Z, gate, phase, focus, address, rot
import QuCircuit: ControlBlock
import QuCircuit: nqubit, ninput, noutput, isunitary, ispure
import QuCircuit: apply!, dispatch!
import QuCircuit: _single_control_gate_sparse,
                  _single_inverse_control_gate_sparse,
                  A_kron_B
import QuCircuit: CONST_SPARSE_P0, CONST_SPARSE_P1

@testset "control matrix form" begin

⊗ = kron
U = sparse(X())
Id = speye(Compat.ComplexF64, 2)

@testset "single control" begin
    g = ControlBlock([1, ], X(), 2)
    @test nqubit(g) == 2
    mat = CONST_SPARSE_P0() ⊗ eye(U) + CONST_SPARSE_P1() ⊗ U
    @test sparse(g) == mat
end

@testset "single control with inferred size" begin
    g = ControlBlock([2, ], X(), 3)
    @test nqubit(g) == 3
    mat = Id ⊗ (CONST_SPARSE_P0() ⊗ eye(U) + CONST_SPARSE_P1() ⊗ U)
    @test sparse(g) == mat
end

@testset "control with fixed size" begin
    g = ControlBlock(4, [2, ], X(), 3)
    @test nqubit(g) == 4
    mat = Id ⊗ (CONST_SPARSE_P0() ⊗ eye(U) + CONST_SPARSE_P1() ⊗ U) ⊗ Id
    @test sparse(g) == mat
end

@testset "control with blank" begin
    g = ControlBlock(4, [3, ], X(), 2)
    @test nqubit(g) == 4

    mat = Id ⊗ (eye(U) ⊗ CONST_SPARSE_P0() + U ⊗ CONST_SPARSE_P1()) ⊗ Id
    @test sparse(g) == mat
end

@testset "multi control" begin
    g = ControlBlock([2, 3], X(), 4)
    @test nqubit(g) == 4

    op = CONST_SPARSE_P0() ⊗ eye(U) + CONST_SPARSE_P1() ⊗ U
    op = CONST_SPARSE_P0() ⊗ eye(op) + CONST_SPARSE_P1() ⊗ op
    op = Id ⊗ op
    @test sparse(g) == op
end

@testset "multi control with blank" begin
    g = ControlBlock(7, [6, 4, 2], X(), 3) # -> [2, 4, 6]
    @test nqubit(g) == 7

    op = CONST_SPARSE_P0() ⊗ eye(U) + CONST_SPARSE_P1() ⊗ U # 2, 3
    op = eye(op) ⊗ CONST_SPARSE_P0() + op ⊗ CONST_SPARSE_P1() # 2, 3, 4
    op = eye(op) ⊗ Id ⊗ CONST_SPARSE_P0() + op ⊗ Id ⊗ CONST_SPARSE_P1() # 2, 3, 4, blank, 6
    op = Id ⊗ op # blank, 2, 3, blank, 4, 6
    op = op ⊗ Id # blnak, 2, 3, blank, 4, 6, blank

    @test sparse(g) == op
end

@testset "inverse control" begin
    g = ControlBlock(2, [-1, ], X(), 2)

    op = CONST_SPARSE_P0() ⊗ U + CONST_SPARSE_P1() ⊗ eye(U)
    @test sparse(g) == op
end

end # control matrix form
