using Yao, Yao.EasyBuild
using Test
using Yao.ConstGate
using YaoArrayRegister.SparseArrays

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
    #@show reg.state
    print_table(reg)

    #dt = 2.732π/2
    Ω = 1.0
    τ = 4.29268/Ω/2
    Δ = 0.377371 * Ω
    V = 1e5
    h1 = rydberg_chain(nbits; Ω=Ω, Δ, V)
    h2 = rydberg_chain(nbits; Ω=-Ω, Δ, V)
    levine_pichler_pulse = chain(time_evolve(h1, τ), time_evolve(h2, τ))
    @test mat(levine_pichler_pulse) * reg.state ≈ apply(reg, levine_pichler_pulse).state
    apply!(reg, levine_pichler_pulse)
    # println()
    # print_table(reg)
    println()
    print_table(reg)

    bases = basis(reg)
    for (i,j,v) in zip(findnz(SparseMatrixCSC(round.(mat(levine_pichler_pulse), digits=5)))...)
        abs(v) > 1e-1 && println(bases[i], "→", bases[j], "   ", v)
    end
end