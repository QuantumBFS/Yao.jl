using Test, Random, LinearAlgebra, SparseArrays

using Yao.CacheServers

struct FakeServer{K, ELT} <: Yao.CacheServers.AbstractCacheServer{K, ELT}
end

struct FakeFragment
end

s = FakeServer{Int, FakeFragment}()

# TODO: use custom Exception: InterfaceError
@testset "check apis" begin
    @test_throws MethodError alloc!(s, 1, FakeFragment())
    @test_throws MethodError iscacheable(s, 1)
    @test_throws MethodError iscached(s, 1)
    @test_throws MethodError push!(s, 1, 1)
    @test_throws MethodError update!(FakeFragment(), 1)
    @test_throws MethodError pull(s, 1)
    @test_throws MethodError getindex(s, 1)
    @test_throws MethodError delete!(s, 1)
    @test_throws MethodError clear!(s, 1)
end
