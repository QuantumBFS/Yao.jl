using YaoBlocks, LuxurySparse, SparseArrays, LinearAlgebra
using YaoBlocks.AD
using Test, Random

@testset "zero rand!" begin
    T = ComplexF64
    D = 10
    Random.seed!(2)
    for pm = [pmrand(T, D), Diagonal(randn(T, D)), sprand(T, D,D,0.4)]
        z = zero(pm)
        @test z == zeros(D,D)
    end
end
