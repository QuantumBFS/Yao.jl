using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao.Intrinsics
using Yao.LuxurySparse

@testset "log2i" begin

    for itype in [
            Int8, Int16, Int32, Int64, Int128,
            UInt8, UInt16, UInt32, UInt64, UInt128,
        ]
        @test log2i(itype(2^5)) == 5
        @test typeof(log2i(itype(2^5))) == Int64
    end
end

@testset "bit length" begin

    @test bit_length(8) == 4

end

@testset "batch normalize" begin
    s = rand(3, 4)
    batch_normalize!(s, 1)
    for i = 1:4
        @test sum(s[:, i]) ≈ 1
    end

    s = rand(3, 4)
    ss = batch_normalize(s, 1)
    for i = 1:4
        @test sum(s[:, i]) != 1
        @test sum(ss[:, i]) ≈ 1
    end
end

@testset "hilbertkron" begin
    A,B,C,D = [randn(2,2) for i = 1:4]
    II = speye(2)
    ⊗ = kron
    @test hilbertkron(4, [A, B], [3, 1]) ≈ II ⊗ A ⊗ II ⊗ B
    @test hilbertkron(4, [A ⊗ B, C], [3, 1]) ≈ A ⊗ B ⊗ II ⊗ C
    @test hilbertkron(4, [A ⊗ B], [1]) ≈ II ⊗ II ⊗ A ⊗ B
    @test hilbertkron(4, [A ⊗ B, C ⊗ D], [1, 3]) ≈ C ⊗ D ⊗ A ⊗ B

    U = randn(2,2)
    U2 = randn(4,4)
    m = U2 ⊗ II ⊗ U ⊗ II
    @test m == hilbertkron(5, [U, U2], [2, 4])
end

@testset "reorder" begin
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
