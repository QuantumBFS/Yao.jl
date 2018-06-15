using Compat
using Compat.Test
using Compat.Random
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao
using Yao.Blocks
using Yao.Intrinsics
using Yao.LuxurySparse

@testset "matrices" begin
    ⊗ = kron
    PA = pmrand(2)
    PB = pmrand(2)
    PC = pmrand(2)
    @test reorder(PC ⊗ PB ⊗ PA, [3,1,2]) ≈ PB ⊗ PA ⊗ PC
    @test invorder(PC ⊗ PB ⊗ PA) ≈ PA ⊗ PB ⊗ PC

    DA = Diagonal(randn(2))
    DB = Diagonal(randn(2))
    DC = Diagonal(randn(2))
    @test reorder(DC ⊗ DB ⊗ DA, [3,1,2]) ≈ DB ⊗ DA ⊗ DC
    @test invorder(DC ⊗ DB ⊗ DA) ≈ DA ⊗ DB ⊗ DC

    DA = sprand(2,2,0.5)
    DB = sprand(2,2, 0.5)
    DC = sprand(2,2, 0.5)
    @test reorder(DC ⊗ DB ⊗ DA, [3,1,2]) ≈ DB ⊗ DA ⊗ DC
    @test invorder(DC ⊗ DB ⊗ DA) ≈ DA ⊗ DB ⊗ DC
end
