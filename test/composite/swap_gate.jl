using Test, YaoBlocks, YaoBase, LuxurySparse, YaoArrayRegister

@test_throws LocationConflictError swap(2, 1, 1)
@test swap(2, 1, 2) isa Swap{2}
@test mat(swap(2, 1, 2)) ≈ PermMatrix([1, 3, 2, 4], ones(1 << 2))
@test mat(swap(4, 1, 3)) ≈ linop2dense(s -> instruct!(s, Val(:SWAP), (1, 3)), 4)

@test swap(1, 2)(3) == swap(3, 1, 2)

@testset "check apply" begin
    r = rand_state(2)
    @test apply!(copy(r), YaoBlocks.ConstGate.SWAP) ≈ apply!(copy(r), swap(2, 1, 2))
end

@test occupied_locs(swap(3, 1, 2)) == (1, 2)
@test isunitary(swap(3, 1, 2))
@test ishermitian(swap(3, 1, 2))
@test isreflexive(swap(3, 1, 2))

@testset "pswap gate" begin
    pb = pswap(6, 2, 4, 0.0)
    @test pb isa PSwap{6,Float64}
    @test pb == pswap(2, 4, 0.0)(6)
    reg = rand_state(6)
    @test copy(reg) |> pb ≈ invoke(apply!, Tuple{ArrayReg,PutBlock}, copy(reg), pb)
    @test copy(reg) |> pb ≈ reg

    dispatch!(pb, π)
    @test copy(reg) |> pb ≈ -im * (copy(reg) |> swap(6, 2, 4))
    @test copy(reg) |> pb |> isnormalized
    pb = dispatch(pb, π)
    @test copy(reg) |> pb ≈ -im * (copy(reg) |> swap(6, 2, 4))
    @test copy(reg) |> pb |> isnormalized

    pb = pswap(6, 2, 4, 0.0)
    dispatch!(pb, :random)
    @test copy(reg) |> pb ≈ invoke(apply!, Tuple{ArrayReg,PutBlock}, copy(reg), pb)
    pb = dispatch(pb, :random)
    @test copy(reg) |> pb ≈ invoke(apply!, Tuple{ArrayReg,PutBlock}, copy(reg), pb)
end
