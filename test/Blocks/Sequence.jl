using Compat.Test

import QuCircuit: Sequence, sequence, AbstractBlock
import QuCircuit: Cache, rand_state, state, focus!,
    X, Y, Z, gate, phase, cache, focus, address, chain
# Block Trait
import QuCircuit: nqubit, ninput, noutput, isunitary,
                    iscacheable, cache_type, ispure, get_cache
# Required Methods
import QuCircuit: apply!, update!, cache!


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
