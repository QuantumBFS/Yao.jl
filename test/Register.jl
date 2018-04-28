import QuCircuit: AbstractRegister, Register
import QuCircuit: nqubit, line_orders, nbatch, state, zero_state, rand_state
import QuCircuit: pack_orders!, focus!
import Compat: axes
using Compat.Test

@testset "Constructors" begin

    test_data = zeros(Complex64, 2^5, 3)
    reg = Register(test_data)
    @test typeof(reg) == Register{5, 3, Complex64}
    @test line_orders(reg) == collect(1:5)
    @test nqubit(reg) == 5
    @test nbatch(reg) == 3
    @test state(reg) === test_data

    # zero state initializer
    reg = zero_state(5, 3)
    @test all(state(reg)[1, :] .== 1)

    # rand state initializer
    reg = rand_state(5, 3)
    @test line_orders(reg) == collect(1:5)

    # check default type
    @test eltype(reg) == Complex128

    creg = copy(reg)
    @test state(creg) == state(reg)
    @test line_orders(creg) == line_orders(reg)
    @test state(creg) !== state(reg)
    @test line_orders(creg) !== line_orders(reg) 
end

@testset "Packing" begin

    # conanical shape
    reg = rand_state(5, 3)

    # contiguous
    pack_orders!(reg, 2:4)
    @test line_orders(reg) == [2, 3, 4, 1, 5]
    @test size(state(reg)) == (2^5, 3)

    # in-contiguous
    pack_orders!(reg, [4, 1])
    @test line_orders(reg) == [4, 1, 2, 3, 5]
    @test size(state(reg)) == (2^5, 3)

    pack_orders!(reg, 5)
    @test line_orders(reg) == [5, 4, 1, 2, 3]
    @test size(state(reg)) == (2^5, 3)

    # mixed
    pack_orders!(reg, (5, 2:3))
    @test line_orders(reg) == [5, 2, 3, 4, 1]
    @test size(state(reg)) == (2^5, 3)
end

@testset "Focus" begin

    # conanical shape
    reg = rand_state(5, 3)

    focus!(reg, 2:3)
    @test line_orders(reg) == [2, 3, 1, 4, 5]
    @test size(state(reg)) == (2^2, 2^3*3)

    focus!(reg, (5, 2:3))
    @test line_orders(reg) == [5, 2, 3, 1, 4]
    @test size(state(reg)) == (2^3, 2^2*3)

end
