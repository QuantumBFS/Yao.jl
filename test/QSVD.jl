using QuAlgorithmZoo, Yao
using Test
using Random, LinearAlgebra

@testset "QSVD" begin
    Random.seed!(2)
    # define a matrix of size (2^Na, 2^Nb)
    Na = 2
    Nb = 2

    # the exact result
    M = reshape(rand_state(Na+Nb).state, 1<<Na, 1<<Nb)
    U_exact, S_exact, V_exact = svd(M)

    U, S, V = QuantumSVD(M)

    @test isapprox(U*Diagonal(S)*V', M, atol=1e-2)
    @test isapprox(abs.(S), S_exact, atol=1e-2)
    @test isapprox(U'*U_exact .|> abs2, I, atol=1e-2)
    @test isapprox(V'*V_exact .|> abs2, I, atol=1e-2)
end
