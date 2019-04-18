using Test, YaoArrayRegister

@testset "test fidelity" begin
    reg = rand_state(3)
    reg_ = rand_state(3)
    reg2 = repeat(reg, 3)
    @test fidelity(reg, reg) ≈ [1]
    @test fidelity(reg, reg_)[] < 1
    @test fidelity(reg2, reg2) ≈ [1,1,1]

    # mix
    reg4 = join(reg, reg)
    reg5 = join(reg_, reg_)
    focus!(reg4, 1:3)
    focus!(reg5, 1:3)
    @test isapprox(fidelity(reg, reg_)[], fidelity(reg4, reg5)[], atol=1e-5)
    @test isapprox.(fidelity(reg, reg_)[], fidelity(repeat(reg4, 3), repeat(reg5, 3)), atol=1e-5) |> all
end

@testset "test trace distance" begin
    reg = rand_state(3)
    reg_ = rand_state(3)
    reg2 = repeat(reg, 3)
    dm = ρ(reg)
    dm_ = ρ(reg_)
    dm2 = ρ(reg2)
    @test reg |> probs ≈ dm |> probs
    @test isapprox(tracedist(dm, dm), tracedist(reg, reg), atol=1e-5)
    @test isapprox(tracedist(dm, dm_), tracedist(reg, reg_), atol=1e-5)
    @test isapprox(tracedist(dm2, dm2), tracedist(reg2, reg2), atol=1e-5)

    # mix
    reg4 = join(reg, reg)
    reg5 = join(reg_, reg_)
    focus!(reg4, 1:3)
    focus!(reg5, 1:3)
    dm4 = reg4 |> density_matrix
    dm5 = reg5 |> density_matrix
    @test isapprox(tracedist(dm, dm_)[], tracedist(dm4, dm5)[], atol=1e-5)
    @test isapprox.(tracedist(dm, dm_)[], tracedist(repeat(reg4, 3)|>density_matrix, repeat(reg5, 3)|>density_matrix), atol=1e-5) |> all
end
