using Test, YaoBlocks
import YaoBlocks: Sum, Prod

@testset "construction" begin
    @test X + Y + Z == sum(X, Y, Z)
    @test X + (Y + Z) == sum(X, sum(Y, Z)) == sum(X, Y, Z)

    @test X * Y * Z == prod(X, Y, Z)
    @test X * (Y * Z) == prod(X, prod(Y, Z)) == prod(X, Y, Z)
    @test im * X == Scale(Val(im), X)
end

@testset "merge pauli prod" begin
    @test mat(simplify(X * Y)) ≈ mat(im * Z)
    @test mat(simplify(X * Y * Y)) ≈ mat(- X)
    @test mat(simplify(X * Y * Z)) ≈ mat(im * I2)
end

@testset "eliminate nested" begin
    @test simplify(prod(X, prod(H))) == prod(X, H)
    @test simplify(prod(X)) == X
end

@testset "reduce matrices" begin
    @test mat(prod(X, Y)) ≈ mat(X) * mat(Y)
    @test mat(prod(X, Y)) ≈ mat(simplify(prod(X, Y)))
    @test mat(sum(X, Y)) ≈ mat(X) + mat(Y)
end

@testset "composite strcuture" begin
    g = chain(2, kron(1=>chain(X, Y), 2=>X), control(1, 2=>X))
end
