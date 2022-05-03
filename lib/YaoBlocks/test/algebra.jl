using Test, YaoBlocks, YaoArrayRegister
import YaoBlocks.ConstGate: Toffoli
using YaoAPI: QubitMismatchError
using LinearAlgebra: I

@testset "construction" begin
    @test X + Y + Z == +(X, Y, Z)
    @test sum([X, Y, Z]) == +(X, Y, Z)
    @test X + (Y + Z) == Add(X, Add(Y, Z))

    @test X * Y * Z == *(X, Y, Z)
    @test X * (Y * Z) == *(X, *(Y, Z))
    @test Val(im) * X == Scale(Val(im), X)
    @test X * Val(im) == Scale(Val(im), X)
    @test X * im == Scale(im, X)
    @test im * X == Scale(im, X)
    @test Val(im) * (Val(im) * X) == Scale(Val(-1+0im), X)
    @test im * (im * X) == Scale(-1+0im, X)
    @test (Val(im) * X) * Val(im) == Scale(Val(-1+0im), X)
    @test (im * X) * im == Scale(-1+0im, X)

    @test mat(X - Y) ≈ mat(X) - mat(Y)
    @test mat(X / 2) ≈ 0.5 * mat(X)
end


@testset "block operations" begin
    r = rand_state(1)
    @test copy(r) |> X * Y * Z |> state ≈ mat(X * Y * Z) * state(r)
    @test copy(r) |> X + Y + Z |> state ≈ mat(X + Y + Z) * state(r)
end

@testset "empty add" begin
    c = Add(4)
    @test mat(Float64, c) == zeros(16, 16)
end

@testset "algebra" begin
    @test factor(-X) == -1
    @test -(-X) === X
    @test factor(-(2X)) === -2
    @test factor((2X)*(2X)) == 4
    @test factor((2X)*Y) == 2
    @test factor(X*(2Y)) == 2
    @test 2(-X) isa Scale{Int, 2, Scale{Val{-1}, 2, XGate}}
    @test mat(X^2) ≈ Matrix(I, 2, 2)
end