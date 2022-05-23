using Test
using YaoArrayRegister, Random, LinearAlgebra, SparseArrays, BitBasis


@testset "broadcast register" begin
    reg = rand_state(5; nbatch = 3)
    @test typeof.(reg)[1] <: ArrayReg{2,ComplexF64,<:SubArray}
    @test [reg...] |> length == 3
    @test [rand_state(3; nbatch=2)...] |> length == 2
end

@testset "arithmetics" begin
    nbit = 5
    reg1 = zero_state(5)
    reg2 = arrayreg(bit"00100")
    @test reg1 != reg2
    @test statevec(reg2) == onehot(ComplexF64, BitStr64{nbit}(4))
    reg3 = reg1 + reg2
    reg4 = (reg1 + reg2)'

    @test statevec(reg3) == onehot(ComplexF64, BitStr64{nbit}(4)) + onehot(ComplexF64, BitStr64{nbit}(0))
    @test statevec(reg3 |> normalize!) ==
          (onehot(ComplexF64, BitStr64{nbit}(4)) + onehot(ComplexF64, BitStr64{nbit}(0))) / sqrt(2)
    @test statevec(reg4 |> normalize!) ==
          (onehot(ComplexF64, BitStr64{nbit}(4)) + onehot(ComplexF64, BitStr64{nbit}(0)))' / sqrt(2)
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
    @test norm(reg) ≈ 1
    @test reg' * reg ≈ 1

    @test state(reg1 * 2) == state(reg1) * 2
    @test state(reg1' * 2) == state(reg1') * 2
    @test reg1 * 2 == 2 * reg1
    @test reg1' * 2 == 2 * reg1'
    reg = rand_state(3; nbatch = 2) * 2
    @test norm(reg) ≈ [2.0, 2.0]
end

@testset "partial ⟨bra|ket⟩" begin
    bra = arrayreg(bit"10")
    ket = arrayreg(bit"100") + 2 * arrayreg(bit"110") + 3 * arrayreg(bit"111")

    focus!(ket, 2:3)
    t = bra' * ket
    relax!(t, 1)
    @test state(t) ≈ [1, 0]

    relax!(ket, 2:3)
    focus!(ket, 1)
    focus!(bra, 2)
    @test_throws ErrorException bra' * ket

    reg1 = rand_state(5; nbatch = 10)
    reg2 = rand_state(5; nbatch = 10)
    @test reg1' * reg2 ≈ reg1' .* reg2
    reg1 = rand_state(2; nbatch = 10)
    reg2 = rand_state(5; nbatch = 10)
    focus!(reg2, 2:3)
    @test all(reg1' * reg2 .≈ reg1' .* reg2)
end

@testset "inplace funcs" begin
    for reg in [
            rand_state(5; nbatch = NoBatch()),
            rand_state(5; nbatch = 3),
            transpose_storage(rand_state(5; nbatch = 3)),
        ]
        reg0 = copy(reg)
        @test regscale!(reg, 0.3) ≈ 0.3 * reg0
        reg1 = rand_state(5; nbatch = nbatch(reg))
        reg2 = rand_state(5; nbatch = nbatch(reg))
        reg10 = copy(reg1)
        regsub!(reg1, reg2)
        @test reg1 ≈ reg10 - reg2

        reg1 = rand_state(5; nbatch = nbatch(reg))
        reg2 = rand_state(5; nbatch = nbatch(reg))
        reg10 = copy(reg1)
        regadd!(reg1, reg2)
        @test reg1 ≈ reg10 + reg2
    end
end


@testset "more (push test coverage)" begin
    reg1 = focus!(rand_state(5; nbatch=5), (2, 3))
    reg2 = focus!(rand_state(5), (2, 3))
    @test fidelity(reg1, reg2) ≈ fidelity(reg2, reg1)
    @test join(reg1) == reg1
    us = uniform_state(3; nlevel=3, nbatch=2)
    @test nbatch(us) == 2
    @test nlevel(us) == 3
    println(reg1)
    println(reg2)
    @test von_neumann_entropy(clone(reg2, 3), [2,1]) ≈ fill(von_neumann_entropy(reg2, [1,2]), 3)
end