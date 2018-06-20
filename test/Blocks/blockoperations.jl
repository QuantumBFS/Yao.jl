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

@testset "blockfilter expect" begin
    ghz = (register(bit"0000") + register(bit"1111")) |> normalize!
    obs1 = kron(4, 2=>Z)
    obs2 = kron(4, 2=>X)
    obs3 = repeat(4, X)
    @test expect(obs1, ghz) ≈ 0
    @test expect(obs2, ghz) ≈ 0
    @test expect(obs3, ghz) ≈ 1

    @test blockfilter(ishermitian, chain(2, kron(2, X, P0), repeat(2, Rx(0), (1,2)), kron(2, 2=>Rz(0.3)))) == [kron(2, X, P0), X, P0, repeat(2, Rx(0), (1,2)), Rx(0)]
    @test blockfilter(b->ishermitian(b) && b isa PrimitiveBlock, chain(2, kron(2, X, P0), repeat(2, Rx(0), (1,2)), kron(2, 2=>Rz(0.3)))) == [X, P0, Rx(0)]
end
