using Test, Random, LinearAlgebra, SparseArrays

using Yao
using Yao.Registers
using Yao.Intrinsics

@testset "Math Operations" begin
    nbit = 5
    reg1 = zero_state(5)
    reg2 = register(bit"00100")
    @test reg1!=reg2
    @test statevec(reg2) == onehotvec(ComplexF64, nbit, 4)
    reg3 = reg1 + reg2
    @test statevec(reg3) == onehotvec(ComplexF64, nbit, 4) + onehotvec(ComplexF64, nbit, 0)
    @test statevec(reg3 |> normalize!) == (onehotvec(ComplexF64, nbit, 4) + onehotvec(ComplexF64, nbit, 0))/sqrt(2)
    @test (reg1 + reg2 - reg1) == reg2

    reg = rand_state(4)
    @test all(state(reg + (-reg)).==0)
    @test all(state(reg*2 - reg/0.5) .== 0)
end

