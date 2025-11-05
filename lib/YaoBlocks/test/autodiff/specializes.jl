using YaoBlocks, YaoBlocks.AD
using YaoArrayRegister
using YaoAPI: NotImplementedError
using Random, Test

AA(i, j) = control(i, j => shift(2π / (1 << (i - j + 1))))
B(n, i) = chain(n, i == j ? put(i => H) : AA(j, i) for j = i:n)
qftcirc(n) = chain(B(n, i) for i = 1:n)

function state_numgrad(f, reg)
    map(1:length(reg.state)) do i
        reg.state[i] += 1e-5
        pos = f(reg)
        reg.state[i] -= 2e-5
        neg = f(reg)
        reg.state[i] += 1e-5 + 1e-5im
        ipos = f(reg)
        reg.state[i] -= 2e-5im
        ineg = f(reg)
        reg.state[i] += 1e-5im
        ((pos - neg) + im * (ipos - ineg)) / 2e-5
    end
end

@testset "expect grad" begin
    Random.seed!(2)
    nbit = 4
    c = qftcirc(nbit)
    H = repeat(nbit, X, 1:nbit)
    for reg in [rand_state(nbit), rand_state(nbit; nbatch = 10)]
        adjin, adjparams = expect'(H, reg => c)
        numgrad =
            YaoBlocks.AD.ng(x -> sum(expect(H, reg => dispatch!(c, x))), parameters(c))
        @test adjparams ≈ vec(numgrad)
        numgrad2 = state_numgrad(reg -> sum(expect(H, reg => c)), reg)
        @test isapprox(vec(adjin.state), numgrad2, atol = 1e-4)

        adjin2 = expect'(H, reg)
        numgrad3 = state_numgrad(reg -> sum(expect(H, reg)), reg)
        @test isapprox(vec(adjin2.state), numgrad3, atol = 1e-4)
    end
end

@testset "fidelity grad" begin
    nbit = 4
    Random.seed!(2)
    for nbatch in [NoBatch(), 10]
        reg1 = rand_state(nbit; nbatch = nbatch)
        reg2 = rand_state(nbit; nbatch = nbatch)
        c1 = qftcirc(nbit)
        c2 = chain(put(nbit, 2 => Rx(0.5)), control(nbit, 1, 3 => Ry(0.5)))

        g1, g2 = fidelity'(reg1, reg2)
        @test isapprox(
            vec(g1.state),
            state_numgrad(reg1 -> sum(fidelity(reg1, reg2)), reg1),
            atol = 1e-4,
        )
        @test isapprox(
            vec(g2.state),
            state_numgrad(reg2 -> sum(fidelity(reg1, reg2)), reg2),
            atol = 1e-4,
        )

        (g1, pg1), (g2, pg2) = fidelity'(reg1 => c1, reg2 => c2)
        npg1 = YaoBlocks.AD.ng(
            x -> sum(fidelity(reg1 => dispatch!(c1, x), reg2 => c2)),
            parameters(c1),
        )
        npg2 = YaoBlocks.AD.ng(
            x -> sum(fidelity(reg1 => c1, reg2 => dispatch!(c2, x))),
            parameters(c2),
        )
        @test isapprox(pg1, vec(npg1), atol = 1e-5)
        @test isapprox(pg2, vec(npg2), atol = 1e-5)
        @test isapprox(
            vec(g1.state),
            state_numgrad(reg1 -> sum(fidelity(reg1 => c1, reg2 => c2)), reg1),
            atol = 1e-4,
        )
        @test isapprox(
            vec(g2.state),
            state_numgrad(reg2 -> sum(fidelity(reg1 => c1, reg2 => c2)), reg2),
            atol = 1e-4,
        )
    end

    nbatch = NoBatch()
    reg1 = rand_state(nbit; nbatch = nbatch) |> focus!(2, 1, 4)
    reg2 = rand_state(nbit; nbatch = nbatch) |> focus!(2, 1, 4)
    c1 = qftcirc(3)
    c2 = chain(put(3, 2 => Rx(0.5)), control(3, 1, 3 => Ry(0.5)))

    @test_throws ArgumentError fidelity'(reg1, reg2)
    #g1, g2 = fidelity'(reg1, reg2)
    #@test isapprox(vec(g1.state), state_numgrad(reg1->sum(fidelity(reg1, reg2)), reg1), atol=1e-5)
    #@test isapprox(vec(g2.state), state_numgrad(reg2->sum(fidelity(reg1, reg2)), reg2), atol=1e-5)

    #(g1,pg1), (g2,pg2) = fidelity'(reg1 => c1, reg2 => c2)
    #npg1 = YaoBlocks.AD.ng(x -> sum(fidelity(reg1 => dispatch!(c1, x), reg2=>c2)), parameters(c1))
    #npg2 = YaoBlocks.AD.ng(x -> sum(fidelity(reg1 => c1, reg2 => dispatch!(c2, x))), parameters(c2))
    #@test isapprox(pg1, vec(npg1),atol=1e-5)
    #@test isapprox(pg2, vec(npg2),atol=1e-5)
    #@test isapprox(vec(g1.state), state_numgrad(reg1->sum(fidelity(reg1=>c1, reg2=>c2)), reg1), atol=1e-5)
    #@test isapprox(vec(g2.state), state_numgrad(reg2->sum(fidelity(reg1=>c1, reg2=>c2)), reg2), atol=1e-5)
end

@testset "fidelity2 grad" begin
    nbit = 4
    Random.seed!(2)
    for nbatch in [NoBatch(), 10]
        reg1 = rand_state(nbit; nbatch = nbatch)
        reg2 = rand_state(nbit; nbatch = nbatch)
        c1 = qftcirc(nbit)
        c2 = chain(put(nbit, 2 => Rx(0.5)), control(nbit, 1, 3 => Ry(0.5)))

        g1, g2 = fidelity2'(reg1, reg2)
        @test isapprox(
            vec(g1.state),
            state_numgrad(reg1 -> sum(fidelity2(reg1, reg2)), reg1),
            atol = 1e-4,
        )
        @test isapprox(
            vec(g2.state),
            state_numgrad(reg2 -> sum(fidelity2(reg1, reg2)), reg2),
            atol = 1e-4,
        )

        (g1, pg1), (g2, pg2) = fidelity2'(reg1 => c1, reg2 => c2)
        npg1 = YaoBlocks.AD.ng(
            x -> sum(fidelity2(reg1 => dispatch!(c1, x), reg2 => c2)),
            parameters(c1),
        )
        npg2 = YaoBlocks.AD.ng(
            x -> sum(fidelity2(reg1 => c1, reg2 => dispatch!(c2, x))),
            parameters(c2),
        )
        @test isapprox(pg1, vec(npg1), atol = 1e-5)
        @test isapprox(pg2, vec(npg2), atol = 1e-5)
        @test isapprox(
            vec(g1.state),
            state_numgrad(reg1 -> sum(fidelity2(reg1 => c1, reg2 => c2)), reg1),
            atol = 1e-4,
        )
        @test isapprox(
            vec(g2.state),
            state_numgrad(reg2 -> sum(fidelity2(reg1 => c1, reg2 => c2)), reg2),
            atol = 1e-4,
        )
    end

    nbatch = NoBatch()
    reg1 = rand_state(nbit; nbatch = nbatch) |> focus!(2, 1, 4)
    reg2 = rand_state(nbit; nbatch = nbatch) |> focus!(2, 1, 4)
    c1 = qftcirc(3)
    c2 = chain(put(3, 2 => Rx(0.5)), control(3, 1, 3 => Ry(0.5)))

    @test_throws ArgumentError fidelity'(reg1, reg2)
    #g1, g2 = fidelity'(reg1, reg2)
    #@test isapprox(vec(g1.state), state_numgrad(reg1->sum(fidelity(reg1, reg2)), reg1), atol=1e-5)
    #@test isapprox(vec(g2.state), state_numgrad(reg2->sum(fidelity(reg1, reg2)), reg2), atol=1e-5)

    #(g1,pg1), (g2,pg2) = fidelity'(reg1 => c1, reg2 => c2)
    #npg1 = YaoBlocks.AD.ng(x -> sum(fidelity(reg1 => dispatch!(c1, x), reg2=>c2)), parameters(c1))
    #npg2 = YaoBlocks.AD.ng(x -> sum(fidelity(reg1 => c1, reg2 => dispatch!(c2, x))), parameters(c2))
    #@test isapprox(pg1, vec(npg1),atol=1e-5)
    #@test isapprox(pg2, vec(npg2),atol=1e-5)
    #@test isapprox(vec(g1.state), state_numgrad(reg1->sum(fidelity(reg1=>c1, reg2=>c2)), reg1), atol=1e-5)
    #@test isapprox(vec(g2.state), state_numgrad(reg2->sum(fidelity(reg1=>c1, reg2=>c2)), reg2), atol=1e-5)
end

@testset "operator fideliy" begin
    nbit = 4
    c1 = qftcirc(nbit)
    c2 = chain(put(nbit, 2 => Rx(0.5)), control(nbit, 1, 3 => Ry(0.5)))

    g1, g2 = operator_fidelity'(c1, c2)
    npg1 = YaoBlocks.AD.ng(x -> operator_fidelity(dispatch!(c1, x), c2), parameters(c1))
    npg2 = YaoBlocks.AD.ng(x -> operator_fidelity(c1, dispatch!(c2, x)), parameters(c2))
    @test isapprox(g1, vec(npg1), atol = 1e-5)
    @test isapprox(g2, vec(npg2), atol = 1e-5)
end

@testset "fix #360" begin
    greg, (greg2, gcirc) = fidelity'(rand_state(10), rand_state(10)=>put(10, 1=>X))
    @test gcirc isa Vector
end
