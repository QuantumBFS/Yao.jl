import QuCircuit: AbstractRegister, Register
import QuCircuit: nqubit, nactive, nremain, address, nbatch,
    state, zero_state, rand_state, register
import QuCircuit: focus!
import Compat: axes
using Compat.Test

@testset "Constructors" begin

    test_data = zeros(Complex64, 2^5, 3)
    reg = register(test_data, 3)
    @test typeof(reg) == Register{UInt(3), Complex64}
    @test address(reg) == collect(1:5)
    @test nqubit(reg) == 5
    @test nbatch(reg) == 3
    @test state(reg) === test_data

    # zero state initializer
    reg = zero_state(5, 3)
    @test all(state(reg)[1, :] .== 1)

    # rand state initializer
    reg = rand_state(5, 3)
    @test address(reg) == collect(1:5)

    # check default type
    @test eltype(reg) == Complex128

    creg = copy(reg)
    @test state(creg) == state(reg)
    @test address(creg) == address(reg)
    @test state(creg) !== state(reg)
    @test address(creg) !== address(reg)
end

@testset "Focus" begin

    # conanical shape
    reg = rand_state(5, 3)

    focus!(reg, 2:3)
    @test address(reg) == UInt[2, 3, 1, 4, 5]
    @test size(state(reg)) == (2^2, 2^3*3)
    @test nactive(reg) == 2
    @test nremain(reg) == 3

    focus!(reg, 5, 2:3)
    @test address(reg) == UInt[5, 3, 1, 2, 4]
    @test size(state(reg)) == (2^3, 2^2*3)
    @test nactive(reg) == 3

    reg = rand_state(8)
    focus!(reg, 2, 3, 5)
    @test nactive(reg) == 3
    @test address(reg) == UInt[2, 3, 5, 1, 4, 6, 7, 8]

    focus!(reg, 8, 2)
    @test nactive(reg) == 2
    @test address(reg) == UInt[8, 3, 2, 5, 1, 4, 6, 7]

    focus!(reg, 7)
    @test nactive(reg) == 1
    @test address(reg) == UInt[6, 8, 3, 2, 5, 1, 4, 7]

    focus!(reg, 1:8)
    @test nactive(reg) == 8
    @test address(reg) == UInt[6, 8, 3, 2, 5, 1, 4, 7]
end
