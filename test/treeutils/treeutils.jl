using YaoBlocks, Test
using YaoBlocks.Optimise
using YaoArrayRegister
using YaoBlocks: check_dumpload

block_A(i, j) = control(i, j => shift(2π / (1 << (i - j + 1))))
block_B(n, i) = chain(n, i == j ? put(i => H) : block_A(j, i) for j in i:n)
qft(n) = chain(block_B(n, i) for i in 1:n)

@testset "map address" begin
    # chain, put, concentrator
    c2 = map_address(
        chain(5, subroutine(5, put(2, 2 => X), (4, 1)), put(5, 3 => X)),
        AddressInfo(10, [2, 1, 4, 6, 3]),
    )
    @test c2 == chain(10, subroutine(10, put(2, 2 => X), (6, 2)), put(10, 4 => X))

    # control, kron, rot
    c3 = map_address(
        chain(5, control(5, 2, 1 => Rx(0.3)), kron(5, 2 => Y, 3 => X)),
        AddressInfo(10, [2, 1, 4, 6, 3]),
    )
    @test c3 == chain(10, control(10, 1, 2 => Rx(0.3)), kron(10, 1 => Y, 4 => X))

    # repeat, measure
    c4 = map_address(
        chain(5, repeat(5, Y, (2, 3)), Measure(5), Measure(5; locs = (3, 2, 1))),
        AddressInfo(10, [2, 1, 4, 6, 3]),
    )
    @test c4 == chain(
        10,
        repeat(10, Y, (1, 4)),
        Measure(10; locs = (2, 1, 4, 6, 3)),
        Measure(10; locs = (4, 1, 2)),
    )

    # sum, cache, scale
    c5 = map_address(
        2 * put(5, 2 => X) + Daggered(Scale(Val(2), put(5, 3 => X) |> cache)),
        AddressInfo(10, [2, 1, 4, 6, 3]),
    )
    @test c5 == 2 * put(10, 1 => X) + Daggered(Scale(Val(2), put(10, 4 => X) |> cache))

    # qft
    c = qft(4)
    @test mat(subroutine(10, c, (6, 2, 3, 7))) ≈ mat(map_address(c, AddressInfo(10, [6, 2, 3, 7])))
end


@testset "merge pauli *" begin
    test_merge(a, b) = mat(merge_pauli(a, b)) ≈ (mat(a) * mat(b))

    for a in [X, Y, Z], b in [X, Y, Z]
        @test test_merge(a, b)
    end

    @test mat(simplify(X * Y)) ≈ mat(im * Z)
    @test mat(simplify(im * X * im * Y)) ≈ mat(-im * Z)
    @test mat(simplify(I2 * im * I2)) ≈ mat(im * I2)

    @test mat(simplify(X * Y * Y)) ≈ mat(X) ≈ mat(X) * mat(Y) * mat(Y)
    @test mat(simplify(X * Y * Z)) ≈ mat(im * I2) ≈ mat(X) * mat(Y) * mat(Z)
end

@testset "eliminate nested" begin
    @test simplify(*(X, *(H))) == *(X, H)
    @test simplify(*(X)) == X

    @test simplify(Add(X, Add(X, X))) == 3X
end

@testset "reduce matrices" begin
    @test mat(*(X, Y)) ≈ mat(X) * mat(Y)
    @test mat(*(X, Y)) ≈ mat(simplify(*(X, Y)))
    @test mat(Add(X, Y)) ≈ mat(X) + mat(Y)
end

@testset "composite strcuture" begin
    g = chain(2, kron(1 => chain(X, Y), 2 => X), control(1, 2 => X))
    @test simplify(g) == prod([control(2, 1, 2 => X), kron(2, 1 => (-im * Z), 2 => X)])
end

@testset "to basic types" begin
    # primitive
    @test to_basictypes(X) == X

    # chain, put, concentrator
    @test to_basictypes(chain(5, put(5, 3 => X))) == chain(5, put(5, 3 => X))
    @test to_basictypes(subroutine(5, put(2, 2 => X), (4, 1))) == put(5, 1 => X)
    @test to_basictypes(subroutine(5, Measure(2, locs = (2,)), (4, 1))) == Measure(5; locs = (1,))
    @test to_basictypes(subroutine(5, Measure(2), (4, 1))) == Measure(5; locs = (4, 1))
    @test to_basictypes(subroutine(5, X, (1,))) == put(5, 1 => X)
    @test to_basictypes(put(5, 3 => X)) == put(5, 3 => X)

    # control, kron, rot
    @test to_basictypes(control(5, 2, 1 => Rx(0.3))) == control(5, 2, 1 => Rx(0.3))
    @test to_basictypes(kron(5, 2 => Y, 3 => X)) == chain(put(5, 2 => Y), put(5, 3 => X))

    # repeat, measure
    @test to_basictypes(repeat(5, Y, (2, 3))) == chain(put(5, 2 => Y), put(5, 3 => Y))
    @test to_basictypes(Measure(5)) == Measure(5)
    @test to_basictypes(Measure(5; locs = (3, 2, 1))) == Measure(5; locs = (3, 2, 1))
    @test to_basictypes(Measure(
        5;
        operator = repeat(3, X, 1:3),
        locs = (3, 2, 1),
    )) == Measure(5; operator = repeat(3, X, 1:3), locs = (3, 2, 1))

    # sum, cache, scale
    @test to_basictypes(2 * put(5, 2 => X)) == 2 * put(5, 2 => X)
    @test to_basictypes(put(5, 3 => X) |> cache) == put(5, 3 => X)
    @test to_basictypes(Daggered(X)) == Daggered(X)

    # tobasic_recursive
    sub = chain(
        5,
        Daggered(put(5, 4 => Rx(0.5)) * 2),
        put(5, 3 => ConstGate.P0 + ConstGate.P1),
        kron(5, 3 => X, 4 => Y),
        subroutine(5, kron(X, Z), (3, 2)),
        Measure(5, operator = X, locs = 1),
    )
    c = chain(10, repeat(10, H, 1:10), subroutine(10, sub, 6:10))

    sub2 = chain(
        10,
        Daggered(put(10, 9 => Rx(0.5)) * 2),
        put(10, 8 => ConstGate.P0 + ConstGate.P1),
        chain(put(10, 8 => X), put(10, 9 => Y)),
        chain(put(10, 8 => X), put(10, 7 => Z)),
        Measure(10, operator = X, locs = 6),
    )
    c2 = chain(10, chain(10, [put(10, i => H) for i in 1:10]), sub2)
    @test simplify(c, rules = [to_basictypes]) == c2

    # subroutine, chain, put, kron and control
    c = chain(
        6,
        [
            put(6, 3 => X),
            kron(6, 2 => X, 4 => X),
            chain(6, [subroutine(6, control(2, 1, 2 => Y), (6, 1))]),
        ],
    )
    @test zero_state(6) |> c ≈ zero_state(6) |> simplify(c, rules = [to_basictypes])
end

@testset "replace block" begin
    @test eliminate_nested(chain(
        7,
        chain(7, control(7, 1, 2 => X)),
        put(7, 4 => X),
    )) == chain(7, [control(7, 1, 2 => X), put(7, 4 => X)])
    @test replace_block(
        X => Y,
        chain(put(2, 2 => X), put(2, 1 => Z), kron(X, Y)),
    ) == chain(put(2, 2 => Y), put(2, 1 => Z), kron(Y, Y))
end

include("dumpload.jl")
check_dumpload(qft(5))
