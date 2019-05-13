using Test, YaoBlocks, YaoBase, LuxurySparse, YaoArrayRegister

@test_throws LocationConflictError swap(2, 1, 1)
@test swap(2, 1, 2) isa Swap{2}
@test mat(swap(2, 1, 2)) ≈ PermMatrix([1, 3, 2, 4], ones(1<<2))
@test mat(swap(4, 1, 3)) ≈ linop2dense(s->instruct!(s, Val(:SWAP), (1, 3)), 4)

@test swap(1, 2)(3) == swap(3, 1, 2)

@testset "check apply" begin
    r = rand_state(2)
    @test apply!(copy(r), YaoBlocks.ConstGate.SWAP) ≈ apply!(copy(r), swap(2, 1, 2))
end

@test occupied_locs(swap(3, 1, 2)) == (1, 2)
@test isunitary(swap(3, 1, 2))
@test ishermitian(swap(3, 1, 2))
@test isreflexive(swap(3, 1, 2))
