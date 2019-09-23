using YaoBlocks.AD
using SparseArrays, LuxurySparse
using YaoArrayRegister
using Test

@testset "outer prod" begin
    D = 8
    T = ComplexF64
    for (l, r) in [(randn(T,D), randn(T,D)), (randn(T,D, 3), randn(T,D, 3))]
        a = outerprod(l, r)
        A = Matrix(a)
        B = randn(T,D,D)
        V = randn(T,D)
        @test A * B ≈ a*B
        @test A * A ≈ a*a
        @test B * A ≈ B*a
        @test V' * A ≈ V'*a
        @test A * V ≈ a*V
        @test size(a) == size(A)
        @test size(a,2) == size(A,2)
        @test A[4] == a[4]
        @test A[4,4] == a[4,4]
        @test A' == a'
        @test transpose(A) == transpose(a)
        @test conj(A) == conj(a)
        @test conj!(A) == conj!(a)
        outerprod(ArrayReg(l), ArrayReg(r)) == a
    end
end

@testset "projection" begin
    T = ComplexF64
    D = 8
    for y in [pmrand(T,D), sprand(T, D, D, 0.5), Diagonal(randn(T,D))]
        @test projection(y, y) == y
        l, r = randn(T,D), randn(T,D)
        op = outerprod(l, r)
        @test projection(y, op) == projection(y, Matrix(op))
    end
end
