using Test, YaoArrayRegister
using LinearAlgebra

@testset "test fidelity" begin
    reg = rand_state(3)
    reg_ = rand_state(3)
    reg2 = clone(reg, 3)
    @test fidelity(reg, reg) ≈ 1
    @test fidelity(reg, reg_) < 1
    @test fidelity(reg2, reg2) ≈ [1, 1, 1]

    # mix
    reg4 = join(reg, reg)
    reg5 = join(reg_, reg_)
    focus!(reg4, 1:3)
    focus!(reg5, 1:3)
    @test isapprox(fidelity(reg, reg_), fidelity(reg4, reg5), atol = 1e-5)

    @test isapprox.(
        fidelity(reg, reg_),
        fidelity(clone(reg4, 3), clone(reg5, 3)),
        atol = 1e-5,
    ) |> all

    # batch
    st = rand(ComplexF64, 8, 2)
    reg1 = BatchedArrayReg(st)
    reg2 = rand_state(3)

    @test fidelity(reg1, reg2) ≈
          [fidelity(ArrayReg(st[:, 1]), reg2), fidelity(ArrayReg(st[:, 2]), reg2)]

    @test isapprox.(
        fidelity(reg, reg_),
        fidelity(clone(reg4, 3), clone(reg5, 3)),
        atol = 1e-5,
    ) |> all
end

@testset "test trace distance" begin
    reg = rand_state(3)
    reg_ = rand_state(3)
    reg2 = clone(reg, 3)
    dm = ρ(reg)
    dm_ = ρ(reg_)
    dm2s = ρ.(reg2)
    @test reg |> probs ≈ dm |> probs
    @test isapprox(tracedist(dm, dm), tracedist(reg, reg), atol = 1e-5)
    @test isapprox(tracedist(dm, dm_), tracedist(reg, reg_), atol = 1e-5)
    @test isapprox(tracedist.(dm2s, dm2s), tracedist(reg2, reg2), atol = 1e-5)

    # mix
    reg4 = join(reg, reg)
    reg5 = join(reg_, reg_)
    focus!(reg4, 1:3)
    focus!(reg5, 1:3)
    dm4 = reg4 |> density_matrix
    dm5 = reg5 |> density_matrix
    @test nqubits(dm4) == 3
    @test isapprox(tracedist(dm, dm_)[], tracedist(dm4, dm5)[], atol = 1e-5)
    @test isapprox.(
        tracedist(dm, dm_)[],
        tracedist.(clone(reg4, 3) .|> density_matrix, clone(reg5, 3) .|> density_matrix),
        atol = 1e-5,
    ) |> all
end

@testset "purify" begin
    reg = rand_state(6)
    reg_p = purify(reg |> ρ)
    @test reg_p |> isnormalized
    @test reg_p |> exchange_sysenv |> probs |> maximum ≈ 1
    reg_p = purify(reg |> ρ; num_env = 0)
    @test fidelity(reg, reg_p) ≈ 1

    reg = rand_state(6; nbatch = 10)
    reg_p = BatchedArrayReg(purify.(reg .|> ρ)...)
    @test reg_p |> isnormalized
    @test reg_p |> exchange_sysenv |> probs |> maximum ≈ 1
    reg_p = BatchedArrayReg(purify.(reg .|> ρ; num_env = 0)...)
    @test fidelity(reg, reg_p) ≈ ones(10)
    reg_p = BatchedArrayReg(purify.(reg .|> ρ; num_env = 2)...)
    @test reg_p |> nqubits == 8
end

@testset "reduce density matrix" begin
    reg = (product_state(bit"00000") + product_state(bit"11111")) / sqrt(2)
    rdm = density_matrix(reg, (1,))
    @test Matrix(rdm) ≈ [1/2 0; 0 1/2]
    reg = product_state([1, 0, 0])
    rdm = density_matrix(reg, (1, 2))
    @test Matrix(rdm) ≈ [0 0 0 0; 0 1 0 0; 0 0 0 0; 0 0 0 0]
end

@testset "von_neumann_entropy" begin
    reg = (product_state(bit"00000") + product_state(bit"11111")) / sqrt(2)
    rho = density_matrix(reg)
    p = eigvals(statevec(reg) * statevec(reg)')
    p = max.(p, eps(Float64))
    @test von_neumann_entropy(rho) ≈ -sum(p .* log.(p)) rtol=1e-12

    reg = zero_state(4; nlevel=3)
    r = density_matrix(reg, [1,2])
    @test nqudits(r) == 2
end
