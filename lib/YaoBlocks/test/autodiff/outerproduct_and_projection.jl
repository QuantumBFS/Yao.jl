using YaoBlocks.AD
using SparseArrays, YaoBlocks.LuxurySparse
using YaoArrayRegister
using LinearAlgebra
using Test

@testset "outer prod" begin
    D = 8
    T = ComplexF64
    for (l, r) in [(randn(T, D), randn(T, D)), (randn(T, D, 3), randn(T, D, 3))]
        a = outerprod(l, r)
        A = Matrix(a)
        B = randn(T, D, D)
        V = randn(T, D)
        @test A * B ≈ a * B
        @test A * A ≈ a * a
        @test B * A ≈ B * a
        @test V' * A ≈ V' * a
        @test A * V ≈ a * V
        @test size(a) == size(A)
        @test size(a, 2) == size(A, 2)
        @test A[4] == a[4]
        @test A[4, 4] == a[4, 4]
        @test A' == a'
        @test transpose(A) == transpose(a)
        @test conj(A) == conj(a)
        @test conj!(A) == conj!(a)
        if l isa Vector
            outerprod(ArrayReg(l), ArrayReg(r)) == a
        else
            outerprod(BatchedArrayReg(l), BatchedArrayReg(r)) == a
        end

        a = outerprod(l, r)
        @test rmul!(copy(a), 0.3) ≈ a .* 0.3

        if ndims(a) == 2
            @test AD._sum_A_Bconj(a, B) ≈ AD._sum_A_Bconj(Matrix(a), B)
        end

        @test 3 * a ≈ Matrix(a) * 3
        @test a * 3 ≈ Matrix(a) * 3
    end
end

@testset "projection" begin
    T = ComplexF64
    D = 8
    for y in Any[pmrand(T, D), sprand(T, D, D, 0.5), Diagonal(randn(T, D))]
        @test projection(y, y) == y
        l, r = randn(T, D), randn(T, D)
        op = outerprod(l, r)
        @test projection(y, op) == projection(y, Matrix(op))
    end
end
