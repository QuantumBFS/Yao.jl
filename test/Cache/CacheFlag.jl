using Compat.Test
using QuCircuit

# @testset "check cache" begin
#     g = cache(X())
#     @test_throws KeyError pull(g)
#     update_cache(g)
#     @test pull(g) == sparse(g.block)

#     empty!(g)
#     @test_throws KeyError pull(g)

# end

@testset "check recursive" begin
    g = kron(
        4,
        X(), phase(0.1), rot(:X, 0.1)
    )

    g = cache(g, recursive=true)

    sparse(g)
end
