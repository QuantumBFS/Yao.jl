using Compat.Test

import QuCircuit: X, Y, Z, H
import QuCircuit: gate, phase, rot
import QuCircuit: cache, update_cache, pull
import QuCircuit: dispatch!

import QuCircuit: kron, chain

@testset "inner kron" begin

    circuit = kron(
        cache(phase(0.1)), # default level is 1
        X(),
        cache(phase(0.2)),
    )

end
