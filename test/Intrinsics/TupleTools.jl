using Test, Random, LinearAlgebra, SparseArrays

using Yao
using Yao.Intrinsics

@testset "sort" begin
    p = randperm(10)
    t = (p..., )
    @test sort(t, rev=true) == (sort(p, rev=true)...,)
end
