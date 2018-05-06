using Compat.Test
# type
import QuCircuit: Concentrator
# exported API
import QuCircuit: focus
import QuCircuit: rand_state, nactive, GreaterThan
# Block Trait
import QuCircuit: address, nqubit, ninput, noutput, isunitary, ispure
# Required Methods
import QuCircuit: apply!, dispatch!


@testset "concentrator" begin

    concentrator = Concentrator(2, 3)

    @test address(concentrator) == (2, 3)
    @test ninput(concentrator) == GreaterThan{2}
    @test noutput(concentrator) == 2
    @test nqubit(concentrator) == GreaterThan{2}
    @test isunitary(concentrator) == true
    @test ispure(concentrator) == false

    reg = rand_state(4)
    apply!(reg, concentrator)
    @test nactive(reg) == 2
    @test address(reg) == [2, 3, 1, 4]

    # do nothing
    @test copy(concentrator) == dispatch!(concentrator)

    reg = rand_state(8)
    apply!(reg, focus([2, 3, 5]))
    @test nactive(reg) == 3
    @test address(reg) == [2, 3, 5, 1, 4, 6, 7, 8]

    apply!(reg, focus(8, 2))
    @test nactive(reg) == 2
    @test address(reg) == [8, 2, 3, 5, 1, 4, 6, 7]

    apply!(reg, focus(2:3, 7))
    @test nactive(reg) == length(2:3) + 1
    @test address(reg) == [2, 3, 7, 8, 5, 1, 4, 6]

    reg |> focus(1:8)
    @test nactive(reg) == 8
    @test address(reg) == [1, 2, 3, 4, 5, 6, 7, 8]
end
