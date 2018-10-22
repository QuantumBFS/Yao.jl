using Test, Random, LinearAlgebra, SparseArrays

using Yao
using Yao.Blocks

@testset "pauli group" begin
    @test X*Y == Im(Z)
    @test Im(X)*Im(Y) == -Im(Z)
    @test X*Im(Y) == Neg(Z)
    @test X*Y*Z == Im(I2)
    @test I2*_Im(I2) == _Im(I2)
    @test I2 |> typeof |> tokenof == :I₂
    @test X |> typeof |> tokenof == :σˣ
    @test Y |> typeof |> tokenof == :σʸ
    @test Z |> typeof |> tokenof == :σᶻ
end
