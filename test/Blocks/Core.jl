using Test, Random, LinearAlgebra, SparseArrays

using Yao

@testset "parameters" begin
g = chain(phase(0.1), phase(0.2), X, phase(0.3))

@test nparameters(g) == 3

for (i, each) in enumerate(parameters(g))
    @test each ≈ i * 0.1
end

g = kron(5, 3=>g, X, phase(0.4))
@test nparameters(g) == 4

for (i, each) in enumerate(parameters(g))
    @test each ≈ i * 0.1
end

g = rollrepeat(4, chain(phase(0.1), shift(0.2)))
@test nparameters(g) == 8

for (i, each) in enumerate(parameters(g))
    if i % 2 == 0
        @test each ≈ 0.2
    else
        @test each ≈ 0.1
    end
end

end

@testset "dispatch" begin

    @testset "check parameter dispatch" begin

        g = chain(phase(0.0), phase(0.0))
        dispatch!(g, [1, 2])
        @test parameters(g[1]) ≈ 1
        @test parameters(g[2]) ≈ 2

        g = rollrepeat(4, g)
        dispatch!(g, 1:8)

        for (i, each) in enumerate(parameters(g))
            each ≈ i
        end

        g = kron(4, 1=>phase(0.2), X, phase(0.3))
        dispatch!(g, 1:2)

        @test parameters(g[1]) ≈ 1
        @test parameters(g[3]) ≈ 2

    end

    @testset "check function dispatch" begin
        g = chain(phase(0.0), phase(0.0))
        dispatch!(+, g, [1, 2])
        @test parameters(g[1]) ≈ 1
        @test parameters(g[2]) ≈ 2

        dispatch!(*, g, [0.1, 0.1])
        @test parameters(g[1]) ≈ 0.1
        @test parameters(g[2]) ≈ 0.2

        dispatch!(-, g, [0.1, 0.2])
        @test parameters(g[1]) ≈ 0.0
        @test parameters(g[2]) ≈ 0.0
    end

end
