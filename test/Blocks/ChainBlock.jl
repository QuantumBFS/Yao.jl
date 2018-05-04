using Compat.Test

import QuCircuit: ChainBlock
import QuCircuit: rand_state, state, focus!,
    X, Y, Z, gate, phase, focus, address
# Interface
import QuCircuit: chain
# Block Trait
import QuCircuit: nqubit, ninput, noutput, isunitary, ispure
# Required Methods
import QuCircuit: apply!, dispatch!


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
end
