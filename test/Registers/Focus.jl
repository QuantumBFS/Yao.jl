using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao.Registers
using Yao.Intrinsics

@testset "Focus 1" begin
    # conanical shape
    reg0 = rand_state(5, 3)
    @test focus!(copy(reg0), [1,4,2]) == naive_focus!(copy(reg0), [1,4,2])
    @test relax!(relax!(focus!(focus!(copy(reg0), [1,4,2]), 2), 2, nbit=3), [1,4,2]) == reg0

    reg = focus!(copy(reg0), 2:3)
    @test reg |> probs ≈ hcat([sum(abs2.(reshape(reg.state[i,:], :, 3)), 1)[1,:] for i in 1:4]...)'
    @test size(state(reg)) == (2^2, 2^3*3)
    @test nactive(reg) == 2
    @test nremain(reg) == 3
    @test relax!(reg, 2:3) == reg0
end

@testset "Focus 2" begin
    reg0 = rand_state(8)
    reg = focus!(copy(reg0), 7)
    @test reg |> probs ≈ sum(abs2.(reg.state), 2)[:,1]
    @test nactive(reg) == 1

    reg0 = rand_state(10)
    reg  = focus!(copy(reg0), 1:8)
    @test hypercubic(reg) == reshape(reg0.state, fill(2, 8)...,4)
    @test nactive(reg) == 8
    @test reg0  == relax!(reg, 1:8) == relax!(reg)

    f!, r! = focuspair!(5,3,2)
    @test copy(reg0) |> f! == naive_focus!(copy(reg0), [5,3,2]) == copy(reg0) |> focus!(5,3,2)
    @test copy(reg0) |> f! |> r! == reg0 == copy(reg0) |> focus!(7,3,2) |> relax!(7,3,2)
end

@testset "Focus 3" begin
    reg = rand_state(8)
    F = Focus(8)
    @test copy(reg) |> F(3, 1) |> F() |> F(nothing) ≈ reg
    @test copy(reg) |> F(3, 1) |> nactive == 2
end
