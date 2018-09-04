using Test, Random, LinearAlgebra, SparseArrays

using Yao
using Yao.Blocks

@testset "constructor" begin

    g = Sequential(
        kron(2, X, Y),
        kron(2, 1=>phase(0.1)),
    )

    @test g isa Sequential
    @test g.blocks == [kron(2, X, Y), kron(2, 1=>phase(0.1))]
end

@testset "apply" begin
g = Sequential(
    kron(2, X, Y),
    kron(2, 1=>phase(0.1)),
)

reg = rand_state(2)
@test statevec(apply!(copy(reg), g)) ≈ mat(chain(g...)) * reg
end

@testset "iteration" begin
    test_list = [X, Y, phase(0.1), rot(X, 0.0)]
    g = Sequential(test_list)

    for (src, tg) in zip(g, test_list)
        @test src == tg
    end

    for (src, tg) in zip(eachindex(g), 1:length(test_list))
        @test src == tg
    end
end

@testset "additional" begin
    g = Sequential(X, Y)
    push!(g, Z)
    @test g[3] == Z

    append!(g, [rot(X, 0.0), rot(Y, 0.0)])
    @test g[4] == rot(X, 0.0)
    @test g[5] == rot(Y, 0.0)

    prepend!(g, [phase(0.1)])
    @test g[1] == phase(0.1)
    @test g[2] == X
    @test g[end] == rot(Y, 0.0)
    gg = insert!(g, 4, Z)
    @test gg[4] == Z
end

@testset "traits" begin
    # TODO: check traits when primitive blocks' traits are all defined
    g = Sequential(X, Y)
    @test length(g) == 2
    @test eltype(g) == eltype(g.blocks)
end
