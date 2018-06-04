using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao
using Yao.CacheServers
using Yao.Blocks

@testset "chain" begin
    g = chain(X(), Y(), Z())

    cg = cache(g, recursive=true)
    @test isa(cg, Cached)
    @test isa(g, ChainBlock)

    for each in g
        @test isa(each, PrimitiveBlock)
    end

    for each in cg
        @test isa(each, Cached)
        @test isa(each.block, PrimitiveBlock)
    end

    cg = cache(g)
    @test isa(cg, Cached)
    @test isa(g, ChainBlock)

    for each in g
        @test isa(each, PrimitiveBlock)
    end

    for each in cg
        @test isa(each, PrimitiveBlock)
    end
end

@testset "kron" begin
    g = kron(5, X(), X(), 4=>Y())

    cg = cache(g, recursive=true)
    @test isa(cg, Cached)
    @test isa(g, KronBlock)

    for each in blocks(g)
        @test isa(each, PrimitiveBlock)
    end

    for each in blocks(cg)
        @test isa(each, Cached)
        @test isa(each.block, PrimitiveBlock)
    end

    cg = cache(g)

    for each in blocks(g)
        @test isa(each, PrimitiveBlock)
    end

    for each in blocks(g)
        @test isa(each, PrimitiveBlock)
    end
end

@testset "roll" begin
    g = roll(4, X())
    cg = cache(g, recursive=true)
    @test isa(cg, Cached)
    @test isa(g, Roller)

    for each in blocks(g)
        @test isa(each, PrimitiveBlock)
    end

    for each in blocks(cg)
        @test isa(each, Cached)
    end

    cg = cache(g)
    @test isa(cg, Cached)
    @test isa(g, Roller)

    for each in blocks(g)
        @test isa(each, PrimitiveBlock)
    end

    for each in blocks(cg)
        @test isa(each, PrimitiveBlock)
    end
end
