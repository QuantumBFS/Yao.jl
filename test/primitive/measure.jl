using Test, YaoBase, YaoBlocks, BitBasis, YaoArrayRegister, Random
using StatsBase: mean

@testset "measure ghz" begin
    # GHZ state
    st = normalize!(ArrayReg(bit"0000") + ArrayReg(bit"1111"))
    Random.seed!(1234)

    # measure it at 1, 2
    # should collapse to 0000 or 1111 since entangled
    g = Measure(4; locs = (1, 2))
    @test occupied_locs(g) == (1,2)
    st |> g

    @test g.results[1] == 0 ? st.state[end] == 0 : st.state[1] == 0
    g = Measure(4; locs = (1, 2), resetto = 2)
    @test g.postprocess isa ResetTo{BitStr64{2}}

    m = Measure(4)
    @test occupied_locs(m) == (1,2,3,4)
    @test m.postprocess isa NoPostProcess
end

@testset "resetto" begin
    Random.seed!(1234)

    st = rand_state(5; nbatch = 3)
    g = Measure(5; locs = (1, 2), resetto = bit"00011")
    st |> g
    for k in 1:32
        if !(st.state[k] ≈ 0.0)
            @test all(BitStr64{5}(k - 1)[1:2] .== 1)
        end
    end
    @test Measure(5; locs = (1, 2), resetto = 0b0011).postprocess isa ResetTo{BitStr64{2}}
end

@testset "error handling" begin
    @test_throws ErrorException Measure(5; locs = (1, 2), resetto = bit"00011", remove = true)
    @test_throws ErrorException mat(Measure(5; locs = (1, 2), resetto = bit"00011"))
end


@testset "op-measures" begin
    Random.seed!(1234)

    reg = rand_state(6, nbatch = 10)
    op = repeat(3, X)

    # measure!
    reg2 = reg |> copy
    res = measure!(op, reg2, 2:4)
    res2 = measure!(op, reg2, 2:4)
    @test size(res) == (10,)
    @test res2 == res

    # measure_resetto!
    reg2 = reg |> copy
    res = measure!(ResetTo(0), op, reg2, 2:4)
    reg2 |> repeat(6, H, 2:4)
    res2 = measure!(ResetTo(0), op, reg2, 2:4)
    @test size(res) == (10,) == size(res2)
    @test all(res2 .== 1)

    # measure_remove!
    reg2 = reg |> copy
    res = measure!(RemoveMeasured(), op, reg2, 2:4)
    reg2 |> repeat(3, H, 2:3)
    @test size(res) == (10,)
    @test nqubits(reg2) == 3

    reg = repeat(ArrayReg(ComplexF64[1, -1] / sqrt(2.0)), 10)
    @test measure!(X, reg) |> mean ≈ -1
    reg = repeat(ArrayReg(ComplexF64[1.0, 0]), 1000)
    @test abs(measure!(X, reg) |> mean) < 0.1
end

@testset "op-measures" begin
    reg = rand_state(8; nbatch = 32)
    op = repeat(5, X, 1:5)

    # measure!
    reg2 = reg |> copy
    res = measure!(op, reg2, 2:6)
    res2 = measure!(op, reg2, 2:6)
    @test size(res) == (32,)
    @test res2 == res

    # measure
    reg2 = reg |> copy
    res = measure(op, reg2, 2:6; nshots = 100)
    @test size(res) == (100, 32)
    @test reg ≈ reg2

    # measure_resetto!
    reg2 = reg |> copy
    res = measure!(ResetTo(0), op, reg2, 2:6)
    reg2 |> repeat(8, H, 2:6)
    res2 = measure!(ResetTo(0), op, reg2, 2:6)
    @test size(res) == (32,) == size(res2)
    @test all(res2 .== 1)

    # measure_remove!
    reg2 = reg |> copy
    res = measure!(RemoveMeasured(), op, reg2, 2:6)
    @test size(res) == (32,)

    reg = repeat(ArrayReg([1, -1 + 0im] / sqrt(2.0)), 10)
    @test measure!(X, reg) |> mean ≈ -1
    reg = repeat(ArrayReg([1.0, 0 + 0im]), 1000)
    @test abs(measure!(X, reg) |> mean) < 0.1

    m = Measure(5)
    @test chmeasureoperator(m, X) == Measure(5, operator = X)
end
