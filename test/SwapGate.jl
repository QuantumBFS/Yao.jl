using Test, Random, LinearAlgebra, SparseArrays, LuxurySparse
using YaoBlockTree
using YaoBlockTree: swapapply!
using YaoBase.Math: linop2dense

@testset "matrix" begin
    @test mat(Swap{2, ComplexF64}(1, 2)) ≈ PermMatrix([1, 3, 2, 4], ones(1<<2))
end

@testset "apply" begin
    @test mat(Swap{4, ComplexF64}(1, 3)) ≈ linop2dense(s->swapapply!(s, 1,3), 4)
end
