using Test
using YaoArrayRegister, Random, LinearAlgebra, SparseArrays, BitBasis


@testset "broadcast register" begin
    reg = rand_state(5; nbatch = 3)
    @test typeof.(reg)[1] <: ArrayReg{<:Any,<:Any,<:SubArray}
    @test [reg...] |> length == 3
    @test [rand_state(3)...] |> length == 1
end

@testset "arithmetics" begin
    nbit = 5
    reg1 = zero_state(5)
    reg2 = ArrayReg(bit"00100")
    @test reg1 != reg2
    @test statevec(reg2) == onehot(ComplexF64, nbit, 4)
    reg3 = reg1 + reg2
    reg4 = (reg1 + reg2)'

    @test statevec(reg3) == onehot(ComplexF64, nbit, 4) + onehot(ComplexF64, nbit, 0)
    @test statevec(reg3 |> normalize!) == (onehot(ComplexF64, nbit, 4) +
                                           onehot(ComplexF64, nbit, 0)) / sqrt(2)
    @test statevec(reg4 |> normalize!) == (onehot(ComplexF64, nbit, 4) +
                                           onehot(ComplexF64, nbit, 0))' / sqrt(2)
    @test (reg1 + reg2 - reg1) == reg2
    @test reg1' + reg2' - reg1' == reg2'
    @test isnormalized(reg4)
    @test isnormalized(reg3)

    @test statevec(-reg4) == -statevec(reg4)
    @test statevec(-reg3) == -statevec(reg3)
    reg = rand_state(4)
    @test all(state(reg + (-reg)) .== 0)
    @test all(state(reg * 2 - reg / 0.5) .== 0)

    reg = rand_state(3)
    @test reg' * reg ≈ 1

    @test state(reg1 * 2) == state(reg1) * 2
    @test state(reg1' * 2) == state(reg1') * 2
    @test reg1 * 2 == 2 * reg1
    @test reg1' * 2 == 2 * reg1'
end

@testset "partial ⟨bra|ket⟩" begin
    bra = ArrayReg(bit"10")
    ket = ArrayReg(bit"100") + 2 * ArrayReg(bit"110") + 3 * ArrayReg(bit"111")

    focus!(ket, 2:3)
    t = bra' * ket
    relax!(t, 1)
    @test state(t) ≈ [1, 0]

    relax!(ket, 2:3)
    focus!(ket, 1)
    focus!(bra, 2)
    @test_throws ErrorException bra' * ket
end
