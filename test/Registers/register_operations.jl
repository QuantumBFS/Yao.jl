using Test, Random, LinearAlgebra, SparseArrays

using Yao.Registers, Yao
using Yao.Intrinsics

@testset "reorder" begin
    @test reorder(collect(0:7), [3,2,1]) == [0, 4, 2, 6, 1, 5, 3, 7]
    @test invorder(collect(0:7)) == [0, 4, 2, 6, 1, 5, 3, 7]

    A = randn(2, 2)
    B = randn(2, 2)
    C = randn(2, 2)
    ⊗ = kron
    @test reorder(C ⊗ B ⊗ A, [3,1,2]) ≈ B ⊗ A ⊗ C
    @test invorder(C ⊗ B ⊗ A) ≈ A ⊗ B ⊗ C


    v1, v2, v3 = randn(2), randn(2), randn(2)
    @test repeat(register(v1 ⊗ v2 ⊗ v3), 2) |> invorder! ≈ repeat(register(v3 ⊗ v2 ⊗ v1), 2)

end

@testset "broadcast register" begin
    reg = rand_state(5,3)
    c = put(5, 2=>X)
    ra = copy(reg)
    rb = copy(reg)
    @test all(ra .|> Ref(c) .≈ rb .|> Ref(c))
    @test typeof.(reg)[1] <: DefaultRegister{<:Any, <:Any, <:SubArray}

    @test [reg...] |> length == 3
    @test [rand_state(3)...] |> length == 1
end

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

