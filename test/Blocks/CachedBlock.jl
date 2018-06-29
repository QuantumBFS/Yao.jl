using Compat
using Compat.Test

using Yao
using Yao.Blocks
using CacheServers
using Yao.LuxurySparse

s = DefaultServer{MatrixBlock, CacheFragment}()

@testset "constructor" begin
    @test CachedBlock(s, X, 2) isa CachedBlock{DefaultServer{MatrixBlock, CacheFragment}, XGate{ComplexF64}, 1, ComplexF64}
end

@testset "methods" begin
    g = CachedBlock(s, X, 3)
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
    g = CachedBlock(s, g, 2)

    @test g[1] isa XGate
    @test g[3] isa YGate

    g[4] = Z
    @test g[4] isa ZGate

    g = chain(X, Y)
    g = CachedBlock(s, g, 2)

    @test g[1] isa XGate
    @test g[2] isa YGate

    @test start(g) == start(g.block)
    @test next(g, start(g)) == next(g.block, start(g.block))
    @test done(g, start(g)) == done(g.block, start(g.block))
    @test length(g) == length(g.block)

    @test eltype(g) == eltype(g.block)
    @test blocks(g) == blocks(g.block)
end
