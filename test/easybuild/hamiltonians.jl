using Yao, Yao.EasyBuild
using Test
using Yao.ConstGate
using YaoArrayRegister.SparseArrays

@testset "solving hamiltonian" begin
    nbit = 8
    h = heisenberg(nbit) |> cache
    @test ishermitian(h)
    @test vec(h[:,bit"01001000"] |> cleanup) ≈ mat(h)[:, buffer(bit"01001000")+1]
    h = transverse_ising(nbit, 1.0)
    @test ishermitian(h)
    @test vec(h[:,bit"01001000"] |> cleanup) ≈ mat(h)[:, buffer(bit"01001000")+1]
end

# https://journals.aps.org/prl/abstract/10.1103/PhysRevLett.123.170503
# Acknology: Jonathan Wurtz and Madelyn Cain for extremely helpful discussion!
@testset "Levine Pichler pulse" begin
    nbits = 2
    reg = zero_state(nbits; nlevel=3)
    # prepare all states in (|0> - i|1>)/sqrt(2)
    # time evolve π/4 with the Raman pulse Hamiltonian is equivalent to doing a X rotation π/2
    apply!(reg, time_evolve(rydberg_chain(nbits; r=1.0), π/4))
    expected = join(fill(arrayreg([1.0, -im, 0]; nlevel=3), nbits)...) |> normalize!
    @test reg ≈ expected

    # |11> -> |W>
    reg0 = product_state(dit"11;3")
    te = time_evolve(rydberg_chain(2; Ω=1.0, V=1e5), π/sqrt(2))
    @test fidelity(reg0 |> te, product_state(dit"12;3") + product_state(dit"21;3") |> normalize!) ≈ 1

    # the Levine-Pichler Pulse
    Ω = -1.0   # sign flipped
    τ = 4.29268/Ω
    Δ = 0.377371*Ω
    V = 1e3
    ξ = -3.90242  # sign flipped
    h1 = rydberg_chain(nbits; Ω=Ω, Δ, V)
    h2 = rydberg_chain(nbits; Ω=Ω*exp(im*ξ), Δ, V)
    pulse = chain(time_evolve(h1, τ), time_evolve(h2, τ))
    @test mat(pulse) * reg.state ≈ apply(reg, pulse).state
    @test ishermitian(h1) && ishermitian(h2)

    i, j = dit"01;3", dit"11;3"

    # half pulse drives |11> to |11>
    # the first pulse completes a circle
    @test isapprox(pulse[1][j, j]|> abs, 1; atol=1e-3)

    ang1 = angle(pulse[i, i]) / π
    ang2 = angle(pulse[j, j]) / π
    @test isapprox(abs(pulse[i,i]), 1; atol=1e-2)
    @test isapprox(abs(pulse[j,j]), 1; atol=1e-2)
    @test isapprox(mod(2*ang1 - ang2, 2), 1, atol=1e-2)
end