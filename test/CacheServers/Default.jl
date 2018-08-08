using Test, Random, LinearAlgebra, SparseArrays

using Yao.CacheServers

include("TestFragment.jl")

s = DefaultServer{Scalar, Variable{Float64}}()
var = Scalar(2.0)

@testset "alloc" begin
    alloc!(s, var, Variable(var.val))
    @test s.storage[objectid(var)] isa Variable{Float64}
    @test iscacheable(s, var) == true
    @test iscached(s, var) == true # always cached
end

@testset "push & pull" begin
    push!(s, Grad(3.0), var)
    @test pull(s, var, Grad) == 3.0
    @test pull(s, var, Param) == 2.0

    push!(s, Param(1.0), var)
    @test pull(s, var, Grad) == 3.0
    @test pull(s, var, Param) == 1.0
end

@testset "delete & clear" begin
    clear!(s, var)
    @test pull(s, var, Grad) == 0.0
    delete!(s, var)
    @test_throws KeyError pull(s, var, Grad)
end
