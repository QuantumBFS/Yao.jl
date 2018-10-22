using Yao, Yao.Blocks
using LinearAlgebra
using Test
using QuAlgorithmZoo

@testset "solving hamiltonian" begin
    nbit = 8
    h = heisenberg(nbit) |> cache
    @test ishermitian(h)
    reg = rand_state(nqubits(h))
    E0 = expect(h, reg)/nbit
    reg |> iter_groundstate!(h, niter=1000)
    EG = expect(h, reg)/nbit/4
    @test isapprox(EG, -0.4564, atol=1e-4)

    # using Time Evolution
    reg = rand_state(nqubits(h))
    reg |> itime_groundstate!(h, τ=20)
    EG = expect(h, reg)/nbit/4
    @test isapprox(EG, -0.4564, atol=1e-4)
end

