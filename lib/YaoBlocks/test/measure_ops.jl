using YaoBlocks, YaoArrayRegister, BitBasis
using YaoBlocks: eigenbasis, is_simple_diagonal
using Random, Test
using YaoAPI: QubitMismatchError
using LinearAlgebra

function check_eigenbasis(op)
    E, V = eigenbasis(op)
    mat(V) * mat(E) * mat(V') ≈ mat(op)
end

@testset "eigen basis" begin
    for op in [
        X,
        Y,
        H,
        Z,
        put(4, 2 => X),
        kron(X, Y, Z),
        repeat(3, H, 2:3),
        cache(Rx(0.5)),
        Daggered(Rx(0.5)),
        rot(SWAP, 0.5),
        time_evolve(kron(X, X), 0.5),
        3 * put(3, 2 => X),
        chain(10, put(2 => X), chain(put(4 => Y))),
        chain(10, put(2 => X), chain(put(2 => Y))),
    ]
        @show op
        @test check_eigenbasis(op)
    end
end

@testset "better operator measure" begin
    Random.seed!(21)
    nbit = 3
    for op in [
        put(nbit, 2 => X),
        control(nbit, 2, 1 => X),
        kron(X, X, X),
        put(nbit, (3, 1, 2) => kron(X, Y, Z)),
        repeat(nbit, X, 2:3),
        +(put(nbit, 2 => X), put(nbit, 1 => Rx(π))),
        2.8 * put(nbit, 1 => X),
        chain(nbit, put(nbit, 3 => X), put(nbit, 1 => Z)),
        cache(put(nbit, 2 => X)),
        Daggered(put(nbit, 2 => Rx(0.8))),
    ]
        reg = rand_state(nbit)
        reg2 = copy(reg)
        @show op
        @test isapprox(
            sum(measure(op, reg2; nshots = 100000)) / 100000,
            expect(op, reg),
            rtol = 0.1,
        )
        @test reg ≈ reg2

        reg = rand_state(nbit; nbatch = 10)
        reg2 = copy(reg)
        @test isapprox(
            dropdims(sum(measure(op, reg2; nshots = 100000), dims = 1), dims = 1) / 100000,
            expect(op, reg),
            rtol = 0.1,
        )
        @test reg ≈ reg2
    end
end

@testset "measure op, specify locs" begin
    Random.seed!(21)
    Nbit = 4
    nbit = 3
    locs = (1, 3, 2)
    @test_throws QubitMismatchError measure(X, rand_state(5), locs)
    @test_throws QubitMismatchError measure(X, rand_state(5), AllLocs())
    for op in [
        put(nbit, 2 => X),
        control(nbit, 2, 1 => X),
        kron(X, Y, Z),
        put(nbit, (3, 1, 2) => kron(X, Y, Z)),
        repeat(nbit, X, 2:3),
        +(put(nbit, 2 => X), put(nbit, 1 => Rx(π))),
        2.8 * put(nbit, 1 => X),
        chain(nbit, put(nbit, 3 => X), put(nbit, 1 => Z)),
        cache(put(nbit, 2 => X)),
        Daggered(put(nbit, 2 => Rx(0.8))),
    ]
        reg = rand_state(Nbit)
        reg2 = copy(reg)
        @show op
        @test isapprox(
            sum(measure(op, reg2, locs; nshots = 100000)) / 100000,
            expect(put(Nbit, locs => op), reg),
            rtol = 0.2,
        )
        @test reg ≈ reg2
    end
end

@testset "better operator measure!" begin
    Random.seed!(9)
    nbit = 3
    for op in [
        put(nbit, 2 => X),
        control(nbit, 2, 1 => X),
        kron(X, X, X),
        put(nbit, (3, 1, 2) => kron(X, X, X)),
        repeat(nbit, X, 2:3),
        +(put(nbit, 2 => X), put(nbit, 1 => im * Rx(π))),
        2.8 * put(nbit, 1 => X),
        chain(nbit, put(nbit, 3 => X), put(nbit, 1 => Z)),
        chain(nbit, put(nbit, 3 => X), put(nbit, 3 => Z)),
        cache(put(nbit, 2 => X)),
        Daggered(put(nbit, 2 => im * Rx(π))),
    ]
        @show op
        reg = rand_state(nbit)
        res = measure!(op, reg)
        @test isapprox(res, sum(measure(op, reg; nshots = 100))[1] / 100, rtol = 0.1)

        reg = rand_state(nbit; nbatch = 10)
        res = measure!(op, reg)
        @test isapprox(
            res,
            vec(sum(measure(op, reg; nshots = 100); dims = 1)) / 100,
            rtol = 0.1,
        )
    end
end

@testset "commute to eachother" begin
    @test YaoBlocks.simple_commute_eachother([put(5, 2 => X), put(5, 3 => Y)])
    @test !YaoBlocks.simple_commute_eachother([put(5, 2 => X), put(5, 2 => Y)])
end

@testset "fix measuring add" begin
    circ_wfn = zero_state(2) |> put(2, 1=>H)
    sp = put(2, 1=>(X + Val(1im)*Y)/2)
    X_diff = sp + sp'
    @test measure(X_diff, circ_wfn, nshots=100) |> sum ≈ 100.0
end

@testset "measure operator with post processing" begin
    # measure! and reset
    reg = rand_state(8; nbatch=32)
    op = repeat(5, X, 1:5)
    @test_throws ArgumentError measure!(ResetTo(0), op, reg, 2:6)
    @test_throws ArgumentError measure!(RemoveMeasured(), op, reg, 2:6)
end

@testset "is simple diagonal" begin
    @test !is_simple_diagonal(X)
    @test is_simple_diagonal(Z)
    @test !is_simple_diagonal(matblock(randn(64, 64)))
    @test !is_simple_diagonal(chain([X,Y]))
    @test is_simple_diagonal(chain([Z,Z]))
    @test is_simple_diagonal(rot(Z, 0.5))
    @test !is_simple_diagonal(rot(X, 0.5))
    @test !is_simple_diagonal(time_evolve(X, 0.5))
    @test is_simple_diagonal(time_evolve(Z, 0.5))
    @test is_simple_diagonal(matblock(Diagonal(randn(128))))

    # Rydberg blockade term + zterm
    block = 0.5 * sum([kron(3, 1=>ConstGate.P1, 2=>ConstGate.P1), kron(3, 2=>ConstGate.P1, 3=>ConstGate.P1)]) + 0.5 * sum([put(3, i=>Z) for i=1:3])
    @test eigenbasis(block) == (block, igate(3))
    # Rydberg xterm
    block = 0.5 * sum([put(3, i=>X) for i=1:3])
    @test eigenbasis(block) == (
                0.5 * sum([put(3, i=>Z) for i=1:3]),
                chain([put(3, i=>H) for i=1:3]))
end