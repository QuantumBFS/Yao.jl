using Compat
using Compat.Test
using Compat.Random
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao
using Yao.Blocks
using Yao.Intrinsics
using Yao.LuxurySparse

@testset "blockfilter expect" begin
    ghz = (register(bit"0000") + register(bit"1111")) |> normalize!
    obs1 = kron(4, 2=>Z)
    obs2 = kron(4, 2=>X)
    obs3 = repeat(4, X)
    @test expect(obs1, ghz) ≈ 0
    @test expect(obs2, ghz) ≈ 0
    @test expect(obs3, ghz) ≈ 1

    @test blockfilter(ishermitian, chain(2, kron(2, X, P0), repeat(2, Rx(0), (1,2)), kron(2, 2=>Rz(0.3)))) == [kron(2, X, P0), X, P0, repeat(2, Rx(0), (1,2)), Rx(0)]
    @test blockfilter(b->ishermitian(b) && b isa PrimitiveBlock, chain(2, kron(2, X, P0), repeat(2, Rx(0), (1,2)), kron(2, 2=>Rz(0.3)))) == [X, P0, Rx(0)]
end

@testset "density matrix" begin
    for reg in [rand_state(4), rand_state(4,3)]
        dm = reg |> density_matrix
        op = put(4, 3=>X)
        println(expect(op, dm))
        println(expect(op, reg))
        @test expect(op, dm) ≈ expect(op, reg)
    end
end
