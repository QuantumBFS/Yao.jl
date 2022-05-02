using Yao.EasyBuild
using Test
using Yao.ConstGate

@testset "solving hamiltonian" begin
    nbit = 8
    h = heisenberg(nbit) |> cache
    @test ishermitian(h)
    h = transverse_ising(nbit, 1.0)
    @test ishermitian(h)
end

# https://journals.aps.org/prl/abstract/10.1103/PhysRevLett.123.170503
@testset "Levine Pichler pulse" begin
    nbits = 2
    reg = zero_state(nbits; nlevel=3)
    # prepare all states in (|0> - i|1>)/sqrt(2)
    # time evolve π/4 with the Raman pulse Hamiltonian is equivalent to doing a X rotation π/2
    apply!(reg, time_evolve(rydberg_chain(nbits; r=1.0), π/4))
    expected = join(fill(arrayreg([1.0, -im, 0]; nlevel=3), nbits)...) |> normalize!
    @test reg ≈ expected

    h = rydberg_chain(Ω = 1.0, Δ = 0.377Ω, V=10.0)
end