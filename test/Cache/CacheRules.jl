using Compat.Test
using QuCircuit

import QuCircuit: ChainBlock, KronBlock, Cached, Gate, Roller

@testset "chain" begin
    g = chain(X(), Y(), Z())

    cg = cache(g, recursive=true)
    @test isa(cg, Cached)
    @test isa(g, ChainBlock)

    for each in g
        @test isa(each, Gate)
    end

    for each in cg
        @test isa(each, Cached)
        @test isa(each.block, Gate)
    end

    cg = cache(g)
    @test isa(cg, Cached)
    @test isa(g, ChainBlock)

    for each in g
        @test isa(each, Gate)
    end

    for each in cg
        @test isa(each, Gate)
    end
end

@testset "kron" begin
    g = kron(5, X(), X(), 4=>Y())

    cg = cache(g, recursive=true)
    @test isa(cg, Cached)
    @test isa(g, KronBlock)

    for each in blocks(g)
        @test isa(each, Gate)
    end

    for each in blocks(cg)
        @test isa(each, Cached)
        @test isa(each.block, Gate)
    end

    cg = cache(g)

    for each in blocks(g)
        @test isa(each, Gate)
    end

    for each in blocks(g)
        @test isa(each, Gate)
    end
end

@testset "roll" begin
    g = roll(4, X())
    cg = cache(g, recursive=true)
    @test isa(cg, Cached)
    @test isa(g, Roller)

    for each in blocks(g)
        @test isa(each, Gate)
    end

    for each in blocks(cg)
        @test isa(each, Cached)
    end

    cg = cache(g)
    @test isa(cg, Cached)
    @test isa(g, Roller)

    for each in blocks(g)
        @test isa(each, Gate)
    end

    for each in blocks(cg)
        @test isa(each, Gate)
    end
end
