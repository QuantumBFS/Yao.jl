using Compat.Test
using QuCircuit

import QuCircuit: Cached, cache_matrix, cache_type, iscacheable

@testset "config" begin
c = Cached(X())
@test cache_matrix(c) == cache_matrix(c.block)
@test cache_type(c) == cache_type(c.block)
end

# @testset "apply cache" begin
#     g = cache(X(), 3)

#     # will update cause this operation will use its matrix form
#     @test state(g(register(bit"1"), 2)) == state(register(bit"0"))
#     @test pull(g) == sparse(g.block) # NOTE: direct call of sparse on un-cache

#     @test state(g(register(bit"1"))) == state(register(bit"0"))
# end

@testset "check cache" begin
    g = cache(X())
    @test_throws KeyError pull(g)
    update_cache(g)
    @test pull(g) == sparse(g.block)

    empty!(g)
    @test_throws KeyError pull(g)
end

@testset "check recursive" begin
    g = kron(
        4,
        X(), phase(0.1), Rx(0.1)
    )

    g = cache(g, recursive=true)

    sparse(g)
end
