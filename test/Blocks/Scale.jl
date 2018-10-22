using Test, Random, LinearAlgebra, SparseArrays

using Yao
using Yao.Blocks
import Yao.Blocks: Scale, Neg, Im, _Im

@testset "construction" begin
    @test -2im*X |> datatype == ComplexF64
end
@testset "Scale ==, ≈" begin
    @test -X isa Scale
    @test -X == -X
    @test Scale(X, 1) == X
    @test X == Scale(X, 1)
end


@testset "Scale *, -" begin
    @test 2*X isa Scale
    @test factor(2*X) == 2
    @test factor(X*2) == 2
    @test factor(2*2*X) == 4
    @test factor(2*X*2) == 4
    @test factor(3X * 2Y) == 6im
    @test 3X * 2Y |> mat == 6im*mat(Z)

    @test mat(-X) == -mat(X)
    reg = rand_state(2)
    @test -(copy(reg) |> CNOT) == copy(reg) |> -CNOT
    @test typeof((-X)') == typeof(-(X'))

    @test 2*(copy(reg) |> CNOT) == copy(reg) |> 2*CNOT
    @test typeof((-2*X)') == typeof(-2*(X'))

    blk = kron(4, 2=>Rx(0.3))
    @test first(chsubblocks(-X, [blk]) |> subblocks) == blk

    @test ishermitian(2X)
    @test !isreflexive(2X)
    @test isunitary(im*X)
    @test !ishermitian(im*X)
end

@testset "StaticScale" begin
    @test X*Y isa StaticScale
    @test X*Y == im*Z
    @test X*Y |> mat == im * mat(Z)
    @test typeof((-X)') == typeof(-(X'))

    @test typeof((StaticScale{-2}(X)')) == typeof(StaticScale{-2}(X'))

    @test -Im(X) == staticscale(X, -im) == _Im(X)
    @test -Im(X) isa _Im
    @test -Im(X)' isa Im
    @test staticscale(X, im)*staticscale(X, im) isa Neg
    @test staticscale(X, im)*staticscale(X, -im) isa Pos
    println(X, staticscale(X, -1), staticscale(X, 1im), staticscale(X, -1im), 2*X)

    blk = kron(4, 2=>Rx(0.3))
    @test first(chsubblocks(staticscale(X, -1), [blk]) |> subblocks) == blk
end
