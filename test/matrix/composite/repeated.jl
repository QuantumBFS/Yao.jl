using Test, YaoBlockTree, YaoBase

rp = RepeatedBlock{5}(X, (1,2,3))
@test isreflexive(rp)
@test ishermitian(rp)
@test isunitary(rp)
@test (chsubblocks(rp, [Z]) |> subblocks .== [Z]) |> all
@test collect(occupied_locations(rp)) == [1,2,3]
@test rp |> copy == rp
