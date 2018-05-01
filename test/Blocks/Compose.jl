using Compat.Test

import QuCircuit: ChainBlock, KronBlock
import QuCircuit: Cache, rand_state, state, focus!, X, Y, Z, gate
# Interface
import QuCircuit: chain
# Block Trait
import QuCircuit: line_orders, nqubit, ninput, noutput, isunitary,
                    iscacheable, cache_type, ispure, get_cache
# Required Methods
import QuCircuit: apply!, update!, cache!

@testset "Chain Block" begin

end
