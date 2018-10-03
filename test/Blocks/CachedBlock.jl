using Test, Random, LinearAlgebra, SparseArrays, CacheServers

using Yao
using Yao.Blocks
using LuxurySparse

test_server = DefaultServer{MatrixBlock, CacheFragment}()

@testset "constructor" begin
    @test CachedBlock(test_server, X, 2) isa CachedBlock{DefaultServer{MatrixBlock, CacheFragment}, XGate{ComplexF64}, 1, ComplexF64}
end

@testset "methods" begin
    g = CachedBlock(test_server, X, 3)
    @test_throws KeyError pull(g)

    update_cache(g)
    @test pull(g) ≈ mat(X)

    clear!(g)
    @test_throws KeyError pull(g)

    @test mat(g) ≈ mat(X)

    clear!(g)

    @test state(apply!(register(bit"1"), g)) ≈ state(register(bit"0"))
    @test pull(g) ≈ mat(X)

    clear!(g)
    @test state(apply!(register(bit"1"), g, 2)) ≈ state(register(bit"0"))
    @test_throws KeyError pull(g)
end

@testset "direct inherited methods" begin
    g = kron(4, 1=>X, 3=>Y)
    g = CachedBlock(test_server, g, 2)

    @test g[1] isa XGate
    @test g[3] isa YGate

    g[4] = Z
    @test g[4] isa ZGate

    g = chain(X, Y)
    g = CachedBlock(test_server, g, 2)

    @test g[1] isa XGate
    @test g[2] isa YGate

    @test iterate(g) == iterate(g.block)
    @test length(g) == length(g.block)

    @test eltype(g) == eltype(g.block)
    @test subblocks(g) == (g.block,)

    gg = chain(g, g)
    cgg = CachedBlock(test_server, gg, 2)
    @test cgg isa CachedBlock
    @test parent(cgg)[1] == g
end
