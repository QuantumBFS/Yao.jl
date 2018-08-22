using Test, Random, LinearAlgebra, SparseArrays

using Yao.Registers
using Yao.Intrinsics

@testset "Constructors" begin
    test_data = zeros(ComplexF32, 2^5, 3)
    reg = register(test_data)
    @test typeof(reg) == DefaultRegister{3, ComplexF32}
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
    @test reg'*reg ≈ ones(3, 3)

    # rand state initializer
    reg = rand_state(5, 3)
    @test reg |> probs ≈ abs2.(reg.state)
    @test isnormalized(reg)

    # check default type
    @test eltype(reg) == ComplexF64

    creg = copy(reg)
    @test state(creg) == state(reg)
    @test state(creg) !== state(reg)
end

@testset "Constructors B=1" begin
    test_data = zeros(ComplexF32, 2^5)
    reg = register(test_data)
    @test typeof(reg) == DefaultRegister{1, ComplexF32}
    @test eltype(reg) == ComplexF32
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
    @test eltype(reg) == ComplexF64

    creg = copy(reg)
    @test state(creg) == state(reg)
    @test state(creg) !== state(reg)
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
end

Ints = Union{Vector{Int}, UnitRange{Int}, Int}
function naive_focus!(reg::DefaultRegister{B}, bits::Ints) where B
    nbit = nqubits(reg)
    norder = vcat(bits, setdiff(1:nbit, bits), nbit+1)
    @views reg.state = reshape(permutedims(reshape(reg.state, fill(2, nbit)...,B), norder), :, (1<<(nbit-length(bits)))*B)
    reg
end

function naive_relax!(reg::DefaultRegister{B}, bits::Ints) where B
    nbit = nqubits(reg)
    norder = vcat(bits, setdiff(1:nbit, bits), nbit+1) |> invperm
    @views reg.state = reshape(permutedims(reshape(reg.state, fill(2, nbit)...,B), norder), :, B)
    reg
end

@testset "Focus 1" begin
    # conanical shape
    reg = rand_state(3, 5)
    @test copy(reg) |> extend!(2) |> nactive == 5
    @test copy(reg) |> extend!(2) |> focus!(4,5) |> measure_remove! |> first |> relax! ≈ reg
end

@testset "stack repeat" begin
    reg = register(bit"00000") + register(bit"11001") |> normalize!;
    @test stack(reg, reg) |> nbatch == 2
    @test repeat(reg, 5) |> nbatch == 5

    ⊗ = kron
    v1, v2, v3 = randn(2), randn(2), randn(2)
    @test repeat(register(v1 ⊗ v2 ⊗ v3), 2) |> invorder! ≈ repeat(register(v3 ⊗ v2 ⊗ v1), 2)
    @test repeat(register(v1 ⊗ v2 ⊗ v3), 2) |> reorder!(3,2,1) ≈ repeat(register(v3 ⊗ v2 ⊗ v1), 2)
end

@testset "addbit" begin
    reg = zero_state(3)
    @test addbit!(copy(reg), 3) == zero_state(6)
    reg = rand_state(3, 2)
    @test addbit!(copy(reg), 2) |> state == kron(zero_state(2) |> state, reg |> state)
end

@testset "reg join" begin
    reg1 = rand_state(6)
    reg2 = rand_state(6)
    reg3 = join(reg1, reg2)
    reg4 = join(focus!(copy(reg1), 1:3), focus!(copy(reg2), 1:2))
    @test reg4 |> statevec ≈ focus!(copy(reg3), [1,2,3,7,8,4,5,6,9,10,11,12]) |> statevec
    reg5 = focus!(repeat(reg1, 3), 1:3)
    reg6 = focus!(repeat(reg2, 3), 1:2)
    @test (join(reg5, reg6) |> statevec)[:,1] ≈ reg4 |> statevec
end

@testset "select" begin
    reg = product_state(4, 6, 2)
    # println(focus!(reg, [1,3]))
    select!(focus!(reg, [2,3]), 0b11) |> relax!

    @test reg'*reg ≈ [1 1; 1 1]
end
