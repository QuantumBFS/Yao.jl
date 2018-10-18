using Test, Random, LinearAlgebra, SparseArrays

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

@testset "measure and reset" begin
    reg = rand_state(4)
    res = measure_reset!(reg, (4,))
    result = measure(reg, 10)
    @test all(result .< 8)
end
