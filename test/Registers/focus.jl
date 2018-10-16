using Test, Random, LinearAlgebra, SparseArrays

using Yao.Registers
using Yao.Intrinsics


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
    reg0 = rand_state(5, 3)
    @test focus!(copy(reg0), [1,4,2]) == naive_focus!(copy(reg0), [1,4,2])
    @test relax!(relax!(focus!(focus!(copy(reg0), [1,4,2]), 2), 2, nbit=3), [1,4,2]) == reg0

    reg = focus!(copy(reg0), 2:3)
    @test reg |> probs ≈ hcat([sum(abs2.(reshape(reg.state[i,:], :, 3)), dims=1)[1,:] for i in 1:4]...)'
    @test size(state(reg)) == (2^2, 2^3*3)
    @test nactive(reg) == 2
    @test nremain(reg) == 3
    @test relax!(reg, 2:3) == reg0
end

@testset "Focus 3" begin
    # conanical shape
    reg = rand_state(3, 5)
    @test oneto(reg, 2) |> nactive == 2
    @test reg |> nactive == 3
    @test copy(reg) |> addbit!(2) |> nactive == 5
    reg2 = copy(reg) |> addbit!(2) |> focus!(4,5)
    @test (reg2 |> measure_remove!; reg2) |> relax! ≈ reg
end

@testset "Focus 2" begin
    reg0 = rand_state(8)
    reg = focus!(copy(reg0), 7)
    @test reg |> probs ≈ sum(abs2.(reg.state), dims=2)[:,1]
    @test nactive(reg) == 1

    reg0 = rand_state(10)
    reg  = focus!(copy(reg0), 1:8)
    @test hypercubic(reg) == reshape(reg0.state, fill(2, 8)...,4)
    @test nactive(reg) == 8
    @test reg0  == relax!(reg, 1:8) == relax!(reg)

    reg1 = focus!(copy(reg0), [5,3,2]) do reg
        @test nactive(reg) == 3
        reg
    end
    @test reg1 == reg0
    @test reg0 == copy(reg0) |> focus!(7,3,2) |> relax!(7,3,2)
end

#=
@testset "Focus 3" begin
    reg = rand_state(8)
    F = Focus(8)
    @test copy(reg) |> F(3, 1) |> F() |> F(nothing) ≈ reg
    @test copy(reg) |> F(3, 1) |> nactive == 2
end
=#
