using Test, Random, LinearAlgebra, SparseArrays
using Yao
using Yao.Blocks
using Yao.Blocks: RepeatedBlock

@testset "basic" begin
    rp = RepeatedBlock{5}(X, (1,2,3))
    @test isreflexive(rp)
    @test ishermitian(rp)
    @test isunitary(rp)
    @test (chsubblocks(rp, [Z]) |> subblocks .== [Z]) |> all
    @test usedbits(rp) == [1,2,3]
    @test rp |> copy == rp
    @test rp |> copy !== rp
end
