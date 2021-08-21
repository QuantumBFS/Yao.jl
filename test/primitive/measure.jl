using Test, YaoBase, YaoBlocks, BitBasis, YaoArrayRegister, Random
using StatsBase: mean

@testset "measure ghz" begin
    # GHZ state
    st = normalize!(ArrayReg(bit"0000") + ArrayReg(bit"1111"))
    Random.seed!(1234)

    # measure it at 1, 2
    # should collapse to 0000 or 1111 since entangled
    g = Measure(4; locs = (1, 2))
    @test occupied_locs(g) == (1, 2)
    st |> g
    @test (copy(st) |> g) isa ArrayReg

    @test g.results[1] == 0 ? st.state[end] == 0 : st.state[1] == 0
    g = Measure(4; locs = (1, 2), resetto = 2)
    @test g.postprocess isa ResetTo{BitStr64{2}}

    m = Measure(4)
    @test occupied_locs(m) == (1, 2, 3, 4)
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

    # measure_resetto! and measure_remove! for operators are no-longer supported due to its ill property.
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

    reg = repeat(ArrayReg([1, -1 + 0im] / sqrt(2.0)), 10)
    @test measure!(X, reg) |> mean ≈ -1
    reg = repeat(ArrayReg([1.0, 0 + 0im]), 1000)
    @test abs(measure!(X, reg) |> mean) < 0.1

    m = Measure(5)
    @test chmeasureoperator(m, X) == Measure(5, operator = X)
end

@testset "measure an operator correctly" begin
    op = kron(Z,Z)
    reg = ArrayReg(ComplexF64[1/sqrt(2),0,0,1/sqrt(2)])
    res = measure!(op, reg)
    @test res == 1
    @test reg ≈ ArrayReg(ComplexF64[1/sqrt(2),0,0,1/sqrt(2)])
    reg = uniform_state(2)
    res = measure!(op, reg)
    @test count(!iszero, reg.state) == 2

    # batched
    reg = ArrayReg(reshape(ComplexF64[1/sqrt(2), 0, 0, 1/sqrt(2), 0.5, 0.5, 0.5, 0.5], 4, 2))
    res = measure!(op, reg)
    @test length(reg) == 2 && res[1] == 1
    @test reg.state[:,1] ≈ ComplexF64[1/sqrt(2),0,0,1/sqrt(2)]
    @test count(!iszero, reg.state) == 4
    @test isnormalized(reg)

    # with virtual dimension
    reg = ArrayReg{1}(reshape(ComplexF64[1/sqrt(2), 0, 0, 1/sqrt(2), 0.5, 0.5, 0.5, 0.5], 4, 2)) / sqrt(2)
    res = measure!(op, reg)
    @test length(reg) == 1
    c = count(!iszero, reg.state)
    @test (c == 4 && res ≈ 1) || (c == 2 && res == -1)
    @test isnormalized(reg)

    # measure zero space
    reg = ArrayReg(ComplexF64[1.0])
    res = measure!(matblock(fill(3.0+0im, 1, 1)), reg)
    @test res ≈ 3.0
    @test reg == zero_state(0)
end