using Test, Random, LinearAlgebra, SparseArrays
using StatsBase: mean

using Yao
using Yao.Registers

@testset "select" begin
    reg = product_state(4, 6, 2)
    # println(focus!(reg, [1,3]))
    r1 = select!(focus!(copy(reg), [2,3]), 0b11) |> relax!
    r2= select(focus!(copy(reg), [2,3]), 0b11) |> relax!
    r3= copy(reg) |> focus!(2,3) |> select!(0b11) |> relax!

    @test r1'*r1 ≈ ones(2)
    @test r1 ≈ r2
    @test r3 ≈ r2
end

@testset "measure and reset/remove" begin
    reg = rand_state(4)
    res = measure_reset!(reg, (4,))
    result = measure(reg; nshot=10)
    #println(result)
    @test all(result .< 8)

    reg = rand_state(6) |> focus(1,4,3)
    reg0 = copy(reg)
    res = measure_remove!(reg)
    @test select(reg0, res) |> normalize! ≈ reg

    reg = rand_state(6,5) |> focus!((1:5)...)
    measure_reset!(reg, 1)
    @test nactive(reg) == 5
end

@testset "op-measures" begin
    reg = rand_state(6, 10)
    op = repeat(3, X)

    # measure!
    reg2 = reg |> copy
    res = measure!(op, reg2, 2:4)
    res2 = measure!(op, reg2, 2:4)
    @test size(res) == (10,)
    @test res2 == res

    # measure_reset!
    reg2 = reg |> copy
    res = measure_reset!(op, reg2, 2:4)
    reg2 |> repeat(6, H, 2:4)
    res2 = measure_reset!(op, reg2, 2:4)
    @test size(res) == (10,) == size(res2)
    @test all(res2 .== 1)

    # measure_remove!
    reg2 = reg |> copy
    res = measure_remove!(op, reg2, 2:4)
    reg2 |> repeat(6, H, 2:4)
    @test size(res) == (10,)
    @test nqubits(reg2) == 3

    reg = repeat(register([1,-1]/sqrt(2.0)), 10)
    @test measure!(X, reg) |> mean ≈ -1
    reg = repeat(register([1.0,0]), 1000)
    @test abs(measure!(X, reg) |> mean) < 0.1
end
