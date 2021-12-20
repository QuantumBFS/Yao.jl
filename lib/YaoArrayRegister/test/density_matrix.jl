using Test, YaoArrayRegister

@testset "test fidelity" begin
    reg = rand_state(3)
    reg_ = rand_state(3)
    reg2 = repeat(reg, 3)
    @test fidelity(reg, reg) ≈ 1
    @test fidelity(reg, reg_) < 1
    @test fidelity(reg2, reg2) ≈ [1, 1, 1]

    # mix
    reg4 = join(reg, reg)
    reg5 = join(reg_, reg_)
    focus!(reg4, 1:3)
    focus!(reg5, 1:3)
    @test isapprox(fidelity(reg, reg_), fidelity(reg4, reg5), atol=1e-5)

    @test all(isapprox.(
        fidelity(reg, reg_), fidelity(repeat(reg4, 3), repeat(reg5, 3)), atol=1e-5
    ))

    # batch
    st = rand(ComplexF64, 8, 2)
    reg1 = ArrayReg(st)
    reg2 = rand_state(3)

    @test fidelity(reg1, reg2) ≈
        [fidelity(ArrayReg(st[:, 1]), reg2), fidelity(ArrayReg(st[:, 2]), reg2)]

    @test all(isapprox.(
        fidelity(reg, reg_), fidelity(repeat(reg4, 3), repeat(reg5, 3)), atol=1e-5
    ))
end

@testset "test trace distance" begin
    reg = rand_state(3)
    reg_ = rand_state(3)
    reg2 = repeat(reg, 3)
    dm = ρ(reg)
    dm_ = ρ(reg_)
    dm2 = ρ(reg2)
    @test probs(reg) ≈ probs(dm)
    @test isapprox(tracedist(dm, dm), tracedist(reg, reg), atol=1e-5)
    @test isapprox(tracedist(dm, dm_), tracedist(reg, reg_), atol=1e-5)
    @test isapprox(tracedist(dm2, dm2), tracedist(reg2, reg2), atol=1e-5)

    # mix
    reg4 = join(reg, reg)
    reg5 = join(reg_, reg_)
    focus!(reg4, 1:3)
    focus!(reg5, 1:3)
    dm4 = density_matrix(reg4)
    dm5 = density_matrix(reg5)
    @test isapprox(tracedist(dm, dm_)[], tracedist(dm4, dm5)[], atol=1e-5)
    @test all(isapprox.(
        tracedist(dm, dm_)[],
        tracedist(density_matrix(repeat(reg4, 3)), density_matrix(repeat(reg5, 3))),
        atol=1e-5,
    ))
end

@testset "purify" begin
    reg = rand_state(6)
    reg_p = purify(ρ(reg))
    @test isnormalized(reg_p)
    @test maximum(probs(exchange_sysenv(reg_p))) ≈ 1
    reg_p = purify(ρ(reg); nbit_env=0)
    @test fidelity(reg, reg_p) ≈ 1

    reg = rand_state(6; nbatch=10)
    reg_p = purify(ρ(reg))
    @test isnormalized(reg_p)
    @test maximum(probs(exchange_sysenv(reg_p))) ≈ 1
    reg_p = purify(ρ(reg); nbit_env=0)
    @test fidelity(reg, reg_p) ≈ ones(10)
    reg_p = purify(ρ(reg); nbit_env=2)
    @test nqubits(reg_p) == 8
end

@testset "reduce density matrix" begin
    reg = (product_state(bit"00000") + product_state(bit"11111")) / sqrt(2)
    rdm = density_matrix(reg, (1,))
    @test Matrix(rdm) ≈ [1/2 0; 0 1/2]
    reg = product_state([1, 0, 0])
    rdm = density_matrix(reg, (1, 2))
    @test Matrix(rdm) ≈ [0 0 0 0; 0 1 0 0; 0 0 0 0; 0 0 0 0]
end
