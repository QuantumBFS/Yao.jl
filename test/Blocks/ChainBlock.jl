using Compat.Test

import QuCircuit: ChainBlock
import QuCircuit: rand_state, state, focus!,
    X, Y, Z, gate, phase, focus, address, rot
# Interface
import QuCircuit: chain, kron
# Block Trait
import QuCircuit: nqubit, ninput, noutput, isunitary, ispure
# Required Methods
import QuCircuit: apply!, dispatch!

import QuCircuit: _promote_chain_eltype

@testset "check type inference" begin
    @test _promote_chain_eltype(gate(X)) == Complex128
    @test _promote_chain_eltype(gate(Complex128, X), gate(Complex64, Y)) == Complex128
    @test _promote_chain_eltype(Complex128, gate(Complex128, X), gate(Complex64, Y)) == Complex128
    @test _promote_chain_eltype(gate(Complex32, X), gate(Complex128, Y), gate(Complex64, Z)) == Complex128

    @test _promote_chain_eltype(Complex128, gate(X), gate(Y), gate(Complex64, Z), gate(Complex32, Z)) == Complex128
end

@testset "chain pure" begin

    g = chain(
        kron(gate(X), gate(Y)),
        kron(2, gate(Complex64, Z))
    )

    @test eltype(g) <: Complex128
    @test nqubit(g) == 2
    @test ninput(g) == 2
    @test noutput(g) == 2
    @test isunitary(g) == true
    @test ispure(g) == true

    mat = kron(sparse(gate(Complex64, Z)), speye(2)) * kron(sparse(gate(X)), sparse(gate(Y)))
    @test sparse(g) == mat
    @test full(g) == full(mat)

    reg = rand_state(2)
    @test mat * state(reg) == state(apply!(reg, g))

    # check call method
    @test mat * state(reg) == state(g(reg))

    # check copy

    cg = copy(g)
    for (copied, original) in zip(cg.blocks, g.blocks)
        @test copied !== original
        @test copied == original
    end
end

@testset "parameter chain" begin

    g = chain(
        phase(0.2),
        rot(X, 0.1),
    )

    dispatch!(g, (1, 0.3), (2, 0.5))
    @test g.blocks[1].theta == 0.3
    @test g.blocks[2].theta == 0.5
end
