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

    # |11> -> |W>
    reg0 = product_state(dit"11;3")
    te = time_evolve(rydberg_chain(2; Ω=1.0, V=1e5), π/sqrt(2))
    @test fidelity(reg0 |> te, product_state(dit"12;3") + product_state(dit"21;3") |> normalize!) ≈ 1

    #dt = 2.732π/2
    Ω = 1.0
    τ = 4.29268/Ω
    Δf = 0.377371
    V = 1e3
    ξ = 3.90242
    h1 = rydberg_chain(nbits; Ω=Ω, Δ=Δf*Ω, V)
    h2 = rydberg_chain(nbits; Ω=Ω*exp(im*ξ), Δ=Δf*Ω, V)
    levine_pichler_pulse = chain(time_evolve(h1, 2τ), time_evolve(h2, 2τ))
    # half pulse drives |11> to |11>
    @test isapprox(mat(levine_pichler_pulse[1])[Int(dit"11;3")+1, Int(dit"11;3")+1] |> abs, 1; atol=1e-3)
    @test mat(levine_pichler_pulse) * reg.state ≈ apply(reg, levine_pichler_pulse).state
    reg = apply(reg, levine_pichler_pulse)
    println()
    print_table(reg)

    # TODO: add block[dit"...", dit"..."]
    bases = basis(reg)
    h = levine_pichler_pulse
    m = mat(h)
    i = Int(dit"01;3")+1
    j = Int(dit"11;3")+1
    ang1 = angle(m[i, i]) / π
    ang2 = angle(m[j, j]) / π
    @show 2*ang1 - ang2-1
    # for (i,j,v) in zip(findnz(SparseMatrixCSC(round.(mat(h), digits=5)))...)
    #     abs(v) > 1e-1 && println(bases[i], "→", bases[j], "   ", v)
    # end
end