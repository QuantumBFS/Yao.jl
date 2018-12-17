using Test, Random, LinearAlgebra, SparseArrays
using Statistics: mean

using Yao
using Yao.Registers
using Yao.Intrinsics

@testset "insert_qubit!" begin
    reg = rand_state(5, 10)
    insert_qubit!(reg, 3, nbit=2)
    @test reg |> nqubits == 7
    @test expect(put(7, 3=>Z), reg) .|> tr |> mean ≈ 1
    @test expect(put(7, 4=>Z), reg) .|> tr |> mean ≈ 1
end

@testset "Constructors" begin
    test_data = zeros(ComplexF32, 2^5, 3)
    reg = register(test_data)
    @test typeof(reg) == DefaultRegister{3, ComplexF32, Matrix{ComplexF32}}
    @test nqubits(reg) == 5
    @test nbatch(reg) == 3
    @test state(reg) === test_data
    @test statevec(reg) == test_data
    @test hypercubic(reg) == reshape(test_data, 2,2,2,2,2,3)
    @test !isnormalized(reg)

    # zero state initializer
    reg = zero_state(5, 3)
    @test all(state(reg)[1, :] .== 1)

    # product state initializer
    reg = product_state(5, 2, 3)
    @test all(state(reg)[3, :] .== 1)
    @test reg'*reg ≈ ones(3)

    # rand state initializer
    reg = rand_state(5, 3)
    @test reg |> probs ≈ abs2.(reg.state)
    @test isnormalized(reg)

    # check default type
    @test datatype(reg) == ComplexF64

    creg = copy(reg)
    @test state(creg) == state(reg)
    @test state(creg) !== state(reg)

    reg = rand_state(5,3)
    reg2 = similar(reg)
    @test !(reg2 ≈ reg)
    copyto!(reg2, reg)
    @test reg2 == reg
end

@testset "Constructors B=1" begin
    test_data = zeros(ComplexF32, 2^5)
    reg = register(test_data)
    @test typeof(reg) == DefaultRegister{1, ComplexF32, Matrix{ComplexF32}}
    @test datatype(reg) == ComplexF32
    @test nqubits(reg) == 5
    @test nbatch(reg) == 1
    @test state(reg) == reshape(test_data, :, 1)
    @test statevec(reg) == test_data
    @test hypercubic(reg) == reshape(test_data, 2,2,2,2,2,1)
    @test !isnormalized(reg)

    # zero state initializer
    reg = zero_state(5)
    @test state(reg)[1] == 1

    # rand state initializer
    reg = rand_state(5)
    @test reg |> probs ≈ vec(abs2.(reg.state))
    @test isnormalized(reg)

    # check default type
    @test datatype(reg) == ComplexF64

    creg = copy(reg)
    @test state(creg) == state(reg)
    @test state(creg) !== state(reg)
end

@testset "repeat" begin
    reg = register(bit"00000") + register(bit"11001") |> normalize!;
    @test repeat(reg, 5) |> nbatch == 5

    v1, v2, v3 = randn(2), randn(2), randn(2)
    @test repeat(register(v1 ⊗ v2 ⊗ v3), 2) |> invorder! ≈ repeat(register(v3 ⊗ v2 ⊗ v1), 2)
    @test repeat(register(v1 ⊗ v2 ⊗ v3), 2) |> reorder!(3,2,1) ≈ repeat(register(v3 ⊗ v2 ⊗ v1), 2)
end

@testset "addbit!" begin
    reg = zero_state(3)
    @test addbit!(copy(reg), 3) == zero_state(6)
    reg = rand_state(3, 2)
    @test addbit!(copy(reg), 2) ≈ join(zero_state(2, 2), reg)
    reg = rand_state(3, 1)
    @test addbit!(copy(reg), 2) ≈ join(zero_state(2, 1), reg)
end

@testset "reg join" begin
    reg1 = rand_state(6)
    reg2 = rand_state(6)
    reg3 = join(reg2, reg1)
    reg4 = join(focus!(copy(reg2), 1:2), focus!(copy(reg1), 1:3))
    @test reg4 |> relaxedvec ≈ focus!(copy(reg3), [1,2,3,7,8,4,5,6,9,10,11,12]) |> relaxedvec
    reg5 = focus!(repeat(reg1, 3), 1:3)
    reg6 = focus!(repeat(reg2, 3), 1:2)
    @test (join(reg6, reg5) |> relaxedvec)[:,1] ≈ reg4 |> relaxedvec
end
