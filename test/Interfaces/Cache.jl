using Compat
using Compat.Test

using Yao
using Yao.Blocks

@testset "cache" begin
    @test cache(X; recursive=false) isa CachedBlock
    @test iscacheable(cache(X; recursive=false)) == true

    g = cache(kron(4, 1=>X, 3=>Y), recursive=true)
    mat(g)
    clearall!(g)

    @test_throws KeyError pull(g)
    @test_throws KeyError pull(g[1])
    @test_throws KeyError pull(g[3])

    @test cache(chain(X, Y, Z)) isa CachedBlock
    @test cache(roll(4, X)) isa CachedBlock
end

@testset "cache" begin
    cache(kron(1=>X, Y, Z))(4) isa CachedBlock
    g = cache(kron(1=>X, 3=>phase(0.1)), 3, recursive=true)
    @test g[1] isa CachedBlock
    @test g[3] isa CachedBlock
    @test g isa CachedBlock

    g = cache(
            chain(
                4,
                kron(1=>X, 3=>phase(0.2)),
                rollrepeat(4, rot(X, 0.1))
            ),
            2, recursive=true
        )

    g isa CachedBlock
    g[1] isa CachedBlock
    g[2] isa CachedBlock
end
