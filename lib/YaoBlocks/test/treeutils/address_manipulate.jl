using YaoBlocks, Test
using YaoArrayRegister
using YaoBlocks: check_dumpload

block_A(i, j) = control(i, j => shift(2π / (1 << (i - j + 1))))
block_B(n, i) = chain(n, i == j ? put(i => H) : block_A(j, i) for j = i:n)
qft(n) = chain(block_B(n, i) for i = 1:n)

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
    @test mat(subroutine(10, c, (6, 2, 3, 7))) ≈
          mat(map_address(c, AddressInfo(10, [6, 2, 3, 7])))
end

