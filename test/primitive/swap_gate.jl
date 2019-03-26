using Test, YaoBlockTree, YaoBase, LuxurySparse

@test_throws LocationConflictError swap(2, 1, 1)
@test swap(2, 1, 2) isa Swap{2, ComplexF64}
@test mat(swap(2, 1, 2)) ≈ PermMatrix([1, 3, 2, 4], ones(1<<2))
@test mat(swap(4, 1, 3)) ≈ linop2dense(s->instruct!(s, Val(:SWAP), (1, 3)), 4)
