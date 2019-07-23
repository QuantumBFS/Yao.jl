using Test, YaoBlocks, YaoBase

rp = RepeatedBlock{5}(X, (1,2,3))
@test isreflexive(rp)
@test ishermitian(rp)
@test isunitary(rp)
@test (chsubblocks(rp, [Z]) |> subblocks .== [Z]) |> all
@test occupied_locs(rp) == (1,2,3)
@test rp |> copy == rp
