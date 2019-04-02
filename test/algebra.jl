using Test, YaoBlocks
import YaoBlocks: Sum, Prod

@testset "construction" begin
    @test X + Y + Z == Sum(X, Y, Z)
    @test X + (Y + Z) == Sum(X, Sum(Y, Z)) == Sum(X, Y, Z)

    @test X * Y * Z == Prod(X, Y, Z)
    @test X * (Y * Z) == Prod(X, Prod(Y, Z)) == Prod(X, Y, Z)

    @test im * X == Scale(Val(im), X)
end

@testset "merge pauli prod" begin
    @test simplify(X * Y) == im * Z
    @test simplify(X * Y * Y) == - X
end