using Test, Random, LinearAlgebra, SparseArrays

using Yao
using Yao.Blocks

@testset "constructor" begin

    g = ChainBlock(
        kron(2, 1=>X, 2=>Y),
        kron(2, 1=>phase(0.1)),
    )

    @test g isa ChainBlock{2, ComplexF64} # default type
    @test g.blocks == [kron(2, X, Y), kron(2, 1=>phase(0.1))]
    blks = [X, Y, Rx(0.3)]
    @test chsubblocks(g, blks) |> subblocks == blks
    @test g |> parameters == [0.1]
    @test dispatch!(g, :random) |> parameters != [0.1]
    @test dispatch!(g, :zero) |> parameters == [0.0]
    @test dispatch!(+, g, :random) |> parameters != [0.0]
    @test iparameter_type(g) == Union{}

    c1 = ChainBlock(put(500, 1=>X), put(500, 3=>Y))
    c2 = ChainBlock(put(500, 4=>X), put(500, 5=>Y))
    @test iscommute(c1, c2)
    @test iscommute(c1, c2, c2)
    @test ishermitian(ChainBlock(c1, c2))
end

@testset "matrix" begin
g = ChainBlock(
    kron(2, 1=>X, 2=>Y),
    kron(2, 1=>phase(0.1))
)

m = mat(kron(2, 1=>phase(0.1))) * mat(kron(2, X, Y))
@test mat(g) ≈ m

g = ChainBlock(
    kron(4, 1=>X, 2=>Y),
    kron(4, 1=>phase(0.1)),
)

@test usedbits(g) == [1, 2]
@test addrs(g) == [1, 1]
end

@testset "apply" begin
g = ChainBlock(
    kron(2, X, Y),
    kron(2, 1=>phase(0.1)),
)

reg = rand_state(2)
@test statevec(apply!(copy(reg), g)) ≈ mat(g) * reg
end

@testset "iteration" begin
    test_list = [X, Y, phase(0.1), rot(X, 0.0)]
    g = ChainBlock(test_list)

    for (src, tg) in zip(g, test_list)
        @test src == tg
    end

    for (src, tg) in zip(eachindex(g), 1:length(test_list))
        @test src == tg
    end
end

@testset "additional" begin
    g = ChainBlock(X, Y)
    push!(g, Z)
    @test g[3] == Z

    append!(g, [rot(X, 0.0), rot(Y, 0.0)])
    @test g[4] == rot(X, 0.0)
    @test g[5] == rot(Y, 0.0)

    prepend!(g, [phase(0.1)])
    @test g[1] == phase(0.1)
    @test g[2] == X
    @test g[end] == rot(Y, 0.0)
    first = popfirst!(g)
    last = pop!(g)
    @test first == phase(0.1)
    @test last == rot(Y, 0.0)
    @test g == chain(1, [X, Y, Z, rot(X, 0.0)])
end

@testset "traits" begin
    # TODO: check traits when primitive blocks' traits are all defined
    g = ChainBlock(X, Y)
    @test isunitary(g) == true
    @test isreflexive(g) == false
    @test ishermitian(g) == false
    @test length(g) == 2
    @test eltype(g) == eltype(g.blocks)
end
