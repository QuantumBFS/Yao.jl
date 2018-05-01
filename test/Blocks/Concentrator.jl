using Compat.Test
# type
import QuCircuit: Concentrator
# exported API
import QuCircuit: focus
import QuCircuit: rand_state, nactive
# Block Trait
import QuCircuit: line_orders, nqubit, ninput, noutput, isunitary,
                    iscacheable, cache_type, ispure, get_cache
# Required Methods
import QuCircuit: apply!, update!, cache!


@testset "concentrator" begin

    concentrator = Concentrator(4, (2, 3))

    @test line_orders(concentrator) == (2, 3)
    @test ninput(concentrator) == 4
    @test noutput(concentrator) == 2
    @test nqubit(concentrator) == 4
    @test isunitary(concentrator) == false
    @test iscacheable(concentrator) == false
    @test ispure(concentrator) == false
    @test get_cache(concentrator) == []

    reg = rand_state(4)
    apply!(reg, concentrator)
    @test nactive(reg) == 2
    @test line_orders(reg) == [2, 3, 1, 4]

    # do nothing
    @test copy(concentrator) == update!(concentrator)
    @test copy(concentrator) == cache!(concentrator, level=2, force=true)

    # check factory method
    @test focus(4, 2, 3) == Concentrator(4, (2, 3))
    @test focus(4, (2, 3)) == Concentrator(4, (2, 3))
end
