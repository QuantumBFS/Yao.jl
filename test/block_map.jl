using Test, YaoBlocks, LinearAlgebra

@testset "block map" begin
    @test BlockMap(ComplexF64, X) isa BlockMap{ComplexF64, typeof(X)}

    @test_throws ErrorException BlockMap(X) * rand(2)
    @test content(BlockMap(X)) === X

    st = rand(ComplexF64, 2)
    @test BlockMap(X) * st ≈ mat(X) * st
    @test issymmetric(BlockMap(X))
    @test size(BlockMap(X)) == (2, 2)
end
