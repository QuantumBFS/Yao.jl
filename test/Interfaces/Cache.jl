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
