using Compat.Test
using QuCircuit


@testset "primitive" begin
    g = cache(phase(0.1))
    update_cache(g)

    empty!(:all) # empty all
    @test_throws KeyError pull(g)
    update_cache(g)
    @test_throws KeyError pull(g)

    g = cache(phase(0.1))
    update_cache(g)
    empty!(g)
    @test_throws KeyError pull(g)
end

@testset "composite" begin
    g = cache(chain(phase(0.1), phase(0.2)))
    update_cache(g)

    empty!(g)
    @test_throws KeyError pull(g)

    g = cache(chain(phase(0.1), phase(0.2)), recursive=true)
    update_cache(g)
    empty!(g)
    @test_throws KeyError pull(g)
    @test pull(g[1]) ≈ sparse(phase(0.1))

    update_cache(g)
    @test sparse(pull(g)) ≈ sparse(g.block)

    empty!(g, recursive=true)
    @test_throws KeyError pull(g)
    @test_throws KeyError pull(g[1])
    @test_throws KeyError pull(g[2])
end
