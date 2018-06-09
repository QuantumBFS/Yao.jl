using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

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

@testset "Constructors B=1" begin
    test_data = zeros(ComplexF32, 2^5)
    reg = register(test_data)
    @test typeof(reg) == DefaultRegister{1, ComplexF32}
    @test eltype(reg) == ComplexF32
    @test nqubits(reg) == 5
    @test nbatch(reg) == 1
    @test state(reg) == reshape(test_data, :, 1)
    @test statevec(reg) == test_data
    @test hypercubic(reg) == reshape(test_data, 2,2,2,2,2)

    # zero state initializer
    reg = zero_state(5)
    @test state(reg)[1] == 1

    # rand state initializer
    reg = rand_state(5)

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
    @test statevec(reg2) == onehotvec(Complex128, nbit, 4)
    reg3 = reg1 + reg2
    @test statevec(reg3) == onehotvec(Complex128, nbit, 4) + onehotvec(Complex128, nbit, 0)
    @test statevec(reg3 |> normalize!) == (onehotvec(Complex128, nbit, 4) + onehotvec(Complex128, nbit, 0))/sqrt(2)
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

@testset "Focus" begin
    # conanical shape
    reg0 = rand_state(5, 3)
    @test focus!(copy(reg0), [1,4,2]) == naive_focus!(copy(reg0), [1,4,2])

    reg = focus!(copy(reg0), 2:3)
    @test size(state(reg)) == (2^2, 2^3*3)
    @test nactive(reg) == 2
    @test nremain(reg) == 3
    @test relax!(reg, 2:3) == reg0

    reg0 = rand_state(8)
    reg = focus!(copy(reg0), 7)
    @test nactive(reg) == 1

    reg0 = rand_state(10)
    reg  = focus!(copy(reg0), 1:8)
    @test nactive(reg) == 8
    @test reg0  == relax!(reg, 1:8)
end
