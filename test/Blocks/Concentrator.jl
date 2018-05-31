using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao
# type
import Yao: Concentrator, GreaterThan

@testset "concentrator" begin

    concentrator = Concentrator(2, 3)

    @test address(concentrator) == (2, 3)
    @test ninput(concentrator) == GreaterThan{2}
    @test noutput(concentrator) == 2
    @test nqubits(concentrator) == GreaterThan{2}
    @test isunitary(concentrator) == true

    reg = rand_state(4)
    apply!(reg, concentrator)
    @test nactive(reg) == 2
    @test address(reg) == [2, 3, 1, 4]

    reg = rand_state(8)
    apply!(reg, focus(2, 3, 5))
    @test nactive(reg) == 3
    @test address(reg) == UInt[2, 3, 5, 1, 4, 6, 7, 8]

    apply!(reg, focus(8, 2))
    @test nactive(reg) == 2
    @test address(reg) == UInt[8, 3, 2, 5, 1, 4, 6, 7]

    apply!(reg, focus(2:3, 7))
    @test nactive(reg) == length(2:3) + 1
    @test address(reg) == UInt[3, 2, 6, 8, 5, 1, 4, 7]

    reg |> focus(1:8)
    @test nactive(reg) == 8
    @test address(reg) == UInt[3, 2, 6, 8, 5, 1, 4, 7]
end
