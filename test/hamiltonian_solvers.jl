using Yao
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

    # using VQE
    N = 4
    h = heisenberg(N)
    E = eigen(h |> mat |> Matrix).values[1]
    c = random_diff_circuit(N, 5, [i=>mod(i,N)+1 for i=1:N], mode=:Merged) |> autodiff(:QC)
    dispatch!(c, :random)
    vqe_solve!(c, h)
    E2 = expect(h, zero_state(N) |> c)
    @test isapprox(E, E2, atol=1e-1)
end
