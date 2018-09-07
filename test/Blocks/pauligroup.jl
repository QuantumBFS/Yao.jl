using Test, Random, LinearAlgebra, SparseArrays

using Yao
using Yao.Blocks

@testset "pauli group" begin
    @test X*Y == im*Z
    @test im*X*(im*Y) == -im*Z
    @test X*(im*Y) == -Z
    @test X*Y*Z == -im*I2
    @test I2*-im*I2 == -im*I2
    @test I2 |> typeof |> tokenof == :I₂
    @test X |> typeof |> tokenof == :σˣ
    @test Y |> typeof |> tokenof == :σʸ
    @test Z |> typeof |> tokenof == :σᶻ
end
