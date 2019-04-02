using Test, YaoArrayRegister, YaoBase

@testset "select" begin
    reg = product_state(4, 6; nbatch=2)
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
    res = measure_collapseto!(reg, (4,))
    @test isnormalized(reg)
    result = measure(reg; nshots=10)
    @test all(result .< 8)

    reg = rand_state(6) |> focus!(1,4,3)
    reg0 = copy(reg)
    res = measure_remove!(reg)
    select(reg0, res)
    @test select(reg0, res) |> normalize! ≈ reg
end
