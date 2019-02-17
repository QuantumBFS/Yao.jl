using Test, YaoArrayRegister, Random, LinearAlgebra, SparseArrays


@testset "broadcast register" begin
    reg = rand_state(5; nbatch=3)
    @test typeof.(reg)[1] <: ArrayReg{<:Any, <:Any, <:SubArray}
    @test [reg...] |> length == 3
    @test [rand_state(3)...] |> length == 1
end

@testset "Math Operations" begin
    nbit = 5
    reg1 = zero_state(5)
    reg2 = ArrayReg(bit"00100")
    @test reg1!=reg2
    @test statevec(reg2) == onehot(ComplexF64, nbit, 4)
    reg3 = reg1 + reg2
    @test statevec(reg3) == onehot(ComplexF64, nbit, 4) + onehot(ComplexF64, nbit, 0)
    @test statevec(reg3 |> normalize!) == (onehot(ComplexF64, nbit, 4) + onehot(ComplexF64, nbit, 0))/sqrt(2)
    @test (reg1 + reg2 - reg1) == reg2

    reg = rand_state(4)
    @test all(state(reg + (-reg)).==0)
    @test all(state(reg*2 - reg/0.5) .== 0)
end
