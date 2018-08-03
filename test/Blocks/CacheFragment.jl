using Compat
using Compat.Test

using Yao.Blocks
using CacheServers
using Yao.LuxurySparse

@testset "constructor" begin
    @test CacheFragment(X) isa CacheFragment{XGate{ComplexF64}, UInt8, Any}
    @test CacheFragment{XGate{ComplexF64}, Int, PermMatrix{ComplexF64, Int}}(X) isa
        CacheFragment{XGate{ComplexF64}, Int, PermMatrix{ComplexF64, Int}}
    @test CacheFragment{XGate{ComplexF64}, Int}(X) isa CacheFragment{XGate{ComplexF64}, Int, Any}
end

@testset "CacheServer API" begin
    frag = CacheFragment(X)
    @test update!(frag, mat(X)) === frag
    @test pull(frag) == mat(X)
    clear!(frag)
    @test_throws KeyError pull(frag)
end
