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
    reg = register(test_data, 3)
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
