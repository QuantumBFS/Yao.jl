using Test, Random, LinearAlgebra, SparseArrays

using Yao
using Yao.Blocks
import Yao.Blocks: Scale, Neg, Im, _Im

@testset "neg" begin
    @test -X isa Neg
    @test -X == -X
    @test -(-X) isa XGate
    @test 2*X isa Scale
    @test getscale(2*X) == 2

    @test mat(-X) == -mat(X)
    reg = rand_state(2)
    @test -(copy(reg) |> CNOT) == copy(reg) |> -CNOT
    @test typeof((-X)') == typeof(-(X'))

    @test 2*(copy(reg) |> CNOT) == copy(reg) |> 2*CNOT
    @test typeof((-2*X)') == typeof(-2*(X'))

    @test -Im(X) == -im*X == _Im(X)
    @test -Im(X) isa _Im
    @test -Im(X)' isa Im
    @test im*X*(im*X) isa Neg
    @test im*X*(-im*X) isa Pos
    println(X, -X, 1im*X, -1im*X, 2*X)

    blk = kron(4, 2=>Rx(0.3))
    @test first(chsubblocks(-X, [blk]) |> subblocks) == blk
end

