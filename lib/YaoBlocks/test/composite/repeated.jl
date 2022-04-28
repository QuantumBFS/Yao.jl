using Test, YaoBlocks, YaoAPI
using LuxurySparse

@testset "baisc" begin
    @test repeat(5, X, 2, 3) isa RepeatedBlock
    @test repeat(5, X, [2, 3]) isa RepeatedBlock
    @test repeat(X, (2,3))(5) == repeat(5, X, (2,3))
    @test repeat(X)(5) == repeat(5, X, 1:5)
    reg = rand_state(5)
    @test apply(reg, repeat(5, X, ())) == reg
    rp = RepeatedBlock(5, X, (1, 2, 3))
    @test iscommute(RepeatedBlock(5, X, (1, 2, 3)), repeat(5, Val(im)*X, (1, 2, 3)))
    @test_throws QubitMismatchError iscommute(RepeatedBlock(5, X, (1, 2, 3)), repeat(3, Val(im)*X, (1, 2, 3)))
    @test iscommute(RepeatedBlock(5, X, (1, 2, 3)), repeat(5, Val(im)*X, (1, 2)))
    @test isreflexive(rp)
    @test ishermitian(rp)
    @test isunitary(rp)
    @test (chsubblocks(rp, [Z]) |> subblocks .== [Z]) |> all
    @test occupied_locs(rp) == (1, 2, 3)
    @test occupied_locs(repeat(5, I2)) == ()
    @test occupied_locs(repeat(5, X)) == (1, 2, 3, 4, 5)
    @test rp |> copy == rp
    @test YaoBlocks.PropertyTrait(rp) == YaoBlocks.PreserveAll()

    @test repeat(10, H, 1:10) == repeat(10, H, Tuple(1:10))
    @test_throws ArgumentError repeat(10, SWAP, (1, 3))

    @test_throws QubitMismatchError apply!(rand_state(2), repeat(10, X, (1, 2, 3)))
    @test_throws QubitMismatchError apply!(rand_state(2), repeat(10, put(1, 1 => X), ()))

    @test mat(repeat(10, X, ())) == IMatrix{1<<10}()
end