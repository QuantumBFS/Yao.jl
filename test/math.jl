using Test, YaoBase, LuxurySparse

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
    II = IMatrix(2)
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

@testset "batched kron" begin
    A, B, C  = rand(4, 4, 3), rand(4, 4, 3), rand(4, 4, 3)
    D = batched_kron(A, B, C)

    tD = zeros(64, 64, 3)
    for k in 1:3
        tD[:, :, k] = kron(A[:, :, k], B[:, :, k], C[:, :, k])
    end

    @test tD ≈ D
end


@testset "random matrices" begin
    mat = rand_unitary(8)
    @test isunitary(mat)
    mat = rand_hermitian(8)
    @test ishermitian(mat)
end
