using Test, QuAlgorithmZoo, Yao
using Random
using QuAlgorithmZoo.NumberTheory

"""Euler theorem states that the order is a devisor of Eulerφ (or the size of Z* group of `N`)"""
function check_Euler_theorem(N::Int)
    Z = Z_star(N)
    Nz = length(Z)   # Eulerφ
    for x in Z
        @test powermod(x,Nz,N) == 1  # the order is a devisor of Eulerφ
    end
end

@testset "Euler" begin
    check_Euler_theorem(150)
end

@testset "Mod" begin
    @test_throws AssertionError Mod{4}(4,10)
    @test_throws AssertionError Mod{2}(3,10)
    m = Mod{4}(3,10)
    @test mat(m) ≈ applymatrix(m)
    @test isunitary(m)
    @test isunitary(mat(m))
    @test m' == Mod{4}(7,10)
end

@testset "KMod" begin
    @test_throws AssertionError KMod{6, 2}(4,10)
    @test_throws AssertionError KMod{4, 2}(3,10)
    m = KMod{6, 2}(3,10)
    @test mat(m) ≈ applymatrix(m)
    @test isunitary(m)
    @test isunitary(mat(m))
    @test m' == KMod{6, 2}(7,10)
end

@testset "shor_classical" begin
    Random.seed!(129)
    L = 35
    f = shor(L, Val(:classical))
    @test f == 5 || f == 7

    L = 25
    f = shor(L, Val(:classical))
    @test f == 5

    L = 7*11
    f = shor(L, Val(:classical))
    @test f == 7 || f == 11

    L = 14
    f = shor(L, Val(:classical))
    @test f == 2 || f == 7

    @test factor_a_power_b(25) == (5, 2)
    @test factor_a_power_b(15) == nothing
end

@testset "shor quantum" begin
    Random.seed!(129)
    L = 15
    f = shor(L, Val(:quantum))
    @test f == 5 || f == 3
end
