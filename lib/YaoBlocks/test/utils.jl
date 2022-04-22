using YaoBlocks
using YaoBlocks: sprand_hermitian, sprand_unitary

@testset "random matrices" begin
    mat = rand_unitary(8)
    @test isunitary(mat)
    mat = rand_hermitian(8)
    @test ishermitian(mat)

    @test ishermitian(sprand_hermitian(8, 0.5))
    @test isunitary(sprand_unitary(8, 0.5))
end

@testset "projector" begin
    @test projector(0) ≈ [1 0; 0 0]
    @test projector(1) ≈ [0 0; 0 1]
end