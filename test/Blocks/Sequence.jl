using Compat.Test

import QuCircuit: Sequence, sequence, AbstractBlock
import QuCircuit: rand_state, state, focus!,
    X, Y, Z, gate, phase, focus, address, chain
# Block Trait
import QuCircuit: nqubit, ninput, noutput, isunitary, ispure
# Required Methods
import QuCircuit: apply!, dispatch!


mutable struct Print <: AbstractBlock
    stream::String
end
apply!(reg, block::Print) = (block.stream = string(reg); reg)

@testset "sequence" begin

    test_print = Print("")
    program = sequence(
        kron(5, gate(X), gate(Y)),
        kron(5, gate(X), 4=>gate(Y)),
        test_print,
    )
    
    reg = rand_state(5)
    apply!(reg, program)
    @test test_print.stream == string(reg)
end
