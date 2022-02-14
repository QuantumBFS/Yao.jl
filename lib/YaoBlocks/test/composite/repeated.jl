using Test, YaoBlocks, YaoBase

rp = RepeatedBlock(5, X, (1, 2, 3))
@test isreflexive(rp)
@test ishermitian(rp)
@test isunitary(rp)
@test (chsubblocks(rp, [Z]) |> subblocks .== [Z]) |> all
@test occupied_locs(rp) == (1, 2, 3)
@test rp |> copy == rp
@test YaoBlocks.PropertyTrait(rp) == YaoBlocks.PreserveAll()

@test repeat(10, H, 1:10) == repeat(10, H, Tuple(1:10))
@test_throws ArgumentError repeat(10, SWAP, (1, 3))

@test_throws QubitMismatchError apply!(rand_state(2), repeat(10, X, (1, 2, 3)))
@test_throws QubitMismatchError apply!(rand_state(2), repeat(10, put(1, 1 => X), ()))

@test mat(repeat(10, X, ())) == IMatrix{1<<10}()
