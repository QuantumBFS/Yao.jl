using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao.Registers

@testset "Constructors" begin

    test_data = zeros(ComplexF32, 2^5, 3)
    reg = register(test_data, 3)
    @test typeof(reg) == DefaultRegister{3, ComplexF32}
    @test nqubits(reg) == 5
    @test nbatch(reg) == 3
    @test state(reg) === test_data

    # zero state initializer
    reg = zero_state(5, 3)
    @test all(state(reg)[1, :] .== 1)

    # rand state initializer
    reg = rand_state(5, 3)

    # check default type
    @test eltype(reg) == ComplexF64

    creg = copy(reg)
    @test state(creg) == state(reg)
    @test state(creg) !== state(reg)
end

@testset "Focus" begin

    # conanical shape
    reg = rand_state(5, 3)

    focus!(reg, 2:3)
    @test size(state(reg)) == (2^2, 2^3*3)
    @test nactive(reg) == 2
    @test nremain(reg) == 3

    reg = rand_state(8)
    focus!(reg, 7)
    @test nactive(reg) == 1

    focus!(reg, 1:8)
    @test nactive(reg) == 8
end
