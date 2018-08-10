using Test, Random, LinearAlgebra, SparseArrays

using Yao.CacheServers

@testset "core APIs" begin
    include("Core.jl")
end

@testset "default" begin
    include("Default.jl")
end

@testset "get global server" begin
    s = get_server(DefaultServer, Int, Dict{Any, Any})
    @test s isa DefaultServer{Int, Dict{Any, Any}}
    cs = get_server(DefaultServer, Int, Dict{Any, Any})

    @test cs === s
end
