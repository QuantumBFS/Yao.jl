using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao

@testset "chain" begin
    @test chain(X(), phase(0.1)) == chain(X(), phase(0.1))

    g = chain(X(), phase(0.1), Y())
    for i = 1:1000
        hash1 = hash(g)
        g[2].theta = rand()
        hash2 = hash(g)
        @test hash1 != hash2
        @test hash2 == hash(g)
    end

end

@testset "kron" begin
    @test kron(4, X(), 3=>phase(0.1), Y()) == kron(4, X(), 3=>phase(0.1), Y())

    g = kron(4, X(), 3=>phase(0.1), Y())
    for i = 1:1000
        hash1 = hash(g)
        g[3].theta = rand()
        hash2 = hash(g)
        @test hash1 != hash2
        @test hash2 == hash(g)
    end

end

@testset "ctrl" begin
    @test control(4, [1, 2], phase(0.1), 3) == control(4, [1, 2], phase(0.1), 3)

    g = control(4, [1, 2], phase(0.1), 3)

    for i = 1:1000
        hash1 = hash(g)
        g[3].theta = rand()
        hash2 = hash(g)
        @test hash1 != hash2
        @test hash2 == hash(g)
    end
end

@testset "roll" begin
    @test roll(4, X) == roll(4, X)
    @test roll(X, X, phase(0.1)) == roll(X, X, phase(0.1))

    g = roll(X, X, phase(0.1))
    for i = 1:1000
        hash1 = hash(g)
        g[3].theta = rand()
        hash2 = hash(g)
        @test hash1 != hash2
        @test hash2 == hash(g)
    end
end
