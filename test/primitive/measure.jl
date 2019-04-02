using Test, YaoBase, YaoBlocks, BitBasis, YaoArrayRegister

@testset "measure ghz" begin
    # GHZ state
    st = normalize!(ArrayReg(bit"0000") + ArrayReg(bit"1111"))

    # measure it at 1, 2
    # should collapse to 0000 or 1111 since entangled
    g = Measure(4, (1, 2))
    st |> g

    @test g.results[1] == 0 ? st.state[end] == 0 : st.state[1] == 0
end

@testset "collapseto" begin
    st = rand_state(5; nbatch=3)
    g = Measure(5, (1, 2); collapseto=bit"11")
    st |> g
    for k in 1:32
        if !(st.state[k] ≈ 0.0)
            @test all(bit(k-1; len=5)[1:2] .== 1)
        end
    end
end

@testset "error handling" begin
    @test_throws ErrorException Measure(5, (1, 2); collapseto=bit"11", remove=true)
    @test_throws ErrorException mat(Measure(5, (1, 2); collapseto=bit"11"))
end
