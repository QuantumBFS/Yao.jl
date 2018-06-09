using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao.Registers
using Yao.Blocks

import Yao.Blocks: measure!, measure_remove!, Measure, MeasureAndRemove

@testset "measure!" begin
    # a GHZ state
    state_array = zeros(ComplexF64, 1<<4)
    state_array[1] = 1/sqrt(2); state_array[end] = 1/sqrt(2);
    reg = register(state_array)

    s, samples = measure!(reg) # measure first qubit
    # we will get
    # |0000> or |1111>
    if samples[1] == 0
        @test state(s)[1] ≈ 1
    else
        @test state(s)[end] ≈ 1
    end
end

@testset "normalize and clapse" begin
    reg = focus!(rand_state(5, 3), 2:3)

    reg2 = copy(reg)
    pre = nothing
    for i in 1:5
        reg2, res = measure!(reg2)
        @test reg2 |> isnormalized
        @test nactive(reg2) == nactive(reg)
        if pre!=nothing
            @test pre == res
        end
        pre = res
    end

    reg2 = copy(reg)
    pre = nothing
    m = Measure()
    for i in 1:5
        reg2 = apply!(reg2, m)
        @test reg2 |> isnormalized
        @test nactive(reg2) == nactive(reg)
        if pre!=nothing
            @test pre == m.result
        end
        pre = m.result
    end
end

@testset "measure and remove" begin
    reg = focus!(rand_state(5, 3), 2:3)
    reg2 = copy(reg)
    mr = MeasureAndRemove()
    apply!(reg2, mr)
    @test nqubits(reg2) == 3
    @test nactive(reg2) == 0
    @test reg2 |> isnormalized
end
