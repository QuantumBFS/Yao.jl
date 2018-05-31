using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao
import Yao: ChainBlock

@testset "constructor" begin

    g = ChainBlock(
        kron(2, X(), Y()),
        kron(2, phase(0.1)),
    )

    @test g.blocks == [kron(2, X(), Y()), kron(2, phase(0.1))]
end

@testset "functionality" begin
    g = ChainBlock(
        kron(2, X(), Y()),
        kron(2, phase(0.1))
    )

    mat = sparse(kron(2, phase(0.1))) * sparse(kron(2, X(), Y()))
    @test sparse(g) == mat
    @test dense(g) == Matrix(mat)

    reg = rand_state(2)
    @test mat * state(reg) == state(apply!(reg, g))

end

@testset "allocation" begin
    g = ChainBlock(X(), phase(0.1))

    cg = copy(g)
    cg[2].theta = 0.2
    @test g[2].theta == 0.1

    sg = similar(g)
    @test_throws BoundsError sg[2]

    sg[1] = X()
    @test sg[1] == X()
    g[1] = Y()
    @test g[1] == Y()
end

@testset "iteration" begin
    test_list = [X(), Y(), phase(0.1), rot(X)]
    g = ChainBlock(test_list)

    for (src, tg) in zip(g, test_list)
        @test src == tg
    end

    for (src, tg) in zip(eachindex(g), 1:length(test_list))
        @test src == tg
    end
end

@testset "additional" begin
    g = ChainBlock(X(), Y())
    push!(g, Z())
    @test g[3] == Z()

    append!(g, [rot(X), rot(Y)])
    @test g[4] == rot(X)
    @test g[5] == rot(Y)

    prepend!(g, [phase(0.1)])
    @test g[1] == phase(0.1)
    @test g[2] == X()
    @test g[end] == rot(Y)
end

@testset "traits" begin
    # TODO: check traits when primitive blocks' traits are all defined

    g = ChainBlock(X(), Y())
    @test isunitary(g) == true
    @test isreflexive(g) == true
    @test ishermitian(g) == true
    @test length(g) == 2
    @test eltype(g) == eltype(g.blocks)
end
