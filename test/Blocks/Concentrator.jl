using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao
# type
using Yao.Blocks

@testset "concentrator" begin

    concentrator = Concentrator(2, 3)

    @test ninput(concentrator) == GreaterThan{2}
    @test noutput(concentrator) == 2
    @test nqubits(concentrator) == GreaterThan{2}
    @test isunitary(concentrator) == true

    reg = rand_state(4)
    apply!(reg, concentrator)
    @test nactive(reg) == 2

    reg = rand_state(8)
    apply!(reg, focus(2, 3, 5))
    @test nactive(reg) == 3

    apply!(reg, focus(8, 2))
    @test nactive(reg) == 2

    apply!(reg, focus(2:3, 7))
    @test nactive(reg) == length(2:3) + 1

    apply!(reg, focus(1:8))
    @test nactive(reg) == 8
end
