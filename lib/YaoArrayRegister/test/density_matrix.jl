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
    dm = density_matrix(reg)
    dm_ = density_matrix(reg_)
    dm2s = density_matrix.(reg2)
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
    reg_p = purify(reg |> density_matrix)
    @test reg_p |> isnormalized
    @test reg_p |> exchange_sysenv |> probs |> maximum ≈ 1
    reg_p = purify(reg |> density_matrix; num_env = 0)
    @test fidelity(reg, reg_p) ≈ 1

    reg = rand_state(6; nbatch = 10)
    reg_p = BatchedArrayReg(purify.(reg .|> density_matrix)...)
    @test reg_p |> isnormalized
    @test reg_p |> exchange_sysenv |> probs |> maximum ≈ 1
    reg_p = BatchedArrayReg(purify.(reg .|> density_matrix; num_env = 0)...)
    @test fidelity(reg, reg_p) ≈ ones(10)
    reg_p = BatchedArrayReg(purify.(reg .|> density_matrix; num_env = 2)...)
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

@testset "density matrix" begin
    # copy, copyto! and similar
    reg = rand_state(3)
    r = density_matrix(reg)
    @test copy(r) == r

    r_manual = DensityMatrix(reg.state * reg.state')
    @test r_manual ≈ r

    r_similar = similar(r)
    @test r_similar isa DensityMatrix
    @test nqubits(r) == nqubits(r_similar)
    @test nlevel(r) == nlevel(r_similar)

    r_rand = rand_density_matrix(3)
    copyto!(r_rand, r)
    @test r_rand  ≈ r

    # pure state
    reg1 = rand_state(3)
    reg2 = rand_state(3)
    r1 = density_matrix(reg1, (2,1,3))
    r2 = density_matrix(reg2, (2,1,3))
    @test isapprox(fidelity(reg1, reg2), fidelity(r1, r2); atol=1e-10)
    
    # mixed state
    r1 = density_matrix(reg1, (2,1))
    r2 = density_matrix(reg2, (2,1))
    expected = abs(tr(sqrt(sqrt(r1.state) * r2.state * sqrt(r1.state))))
    @test isapprox(expected, fidelity(r1, r2); atol=1e-5)

    # focused state is viewed as mixed state
    f1 = focus!(copy(reg1), (2, 1))
    f2 = focus!(copy(reg2), (2, 1))
    @test isapprox(fidelity(r1, r2), fidelity(f1, f2); atol=1e-6)

    # fidelity between focused and pure state
    f1 = rand_state(2)
    @test isapprox(fidelity(density_matrix(f1, (1,2)), r2), fidelity(f1, f2); atol=1e-6)

    dm = rand_density_matrix(2)
    @test is_density_matrix(dm.state)
    @test eltype(dm.state) === ComplexF64

    dm = rand_density_matrix(ComplexF32, 2)
    @test is_density_matrix(dm.state)
    @test eltype(dm.state) === ComplexF32

    dm = rand_density_matrix(2; pure=true)
    @test tr(dm.state^2) ≈ 1
    @test eltype(dm.state) === ComplexF64

    dm = completely_mixed_state(2)
    @test dm.state == I(4)
end

@testset "zero_state_like" begin
    rho = density_matrix(zero_state(3))
    @test zero_state_like(rho, 3) ≈ rho
end

@testset "partial trace" begin
    rho = density_matrix(product_state(bit"001"))
    @test partial_tr(rho, (1,2)) ≈ density_matrix(product_state(bit"0"))
    @test partial_tr(rho, (3,2)) ≈ density_matrix(product_state(bit"1"))
end

@testset "algebra" begin
    r = density_matrix(product_state(bit"001"))
    @test (r + r).state ≈ r.state .* 2
    @test (r - r).state ≈ zero(r.state)
    @test regscale!(copy(r), 3.0).state ≈ r.state .* 3
    @test regadd!(copy(r), r).state ≈ r.state .* 2
    @test regsub!(copy(r), r).state ≈ zero(r.state)
    @test -(r).state ≈ -r.state
end

@testset "printing" begin
    show(stdout, MIME"text/plain"(), rand_density_matrix(3))
end

@testset "join" begin
    r1 = density_matrix(arrayreg(bit"110"))
    r2 = density_matrix(arrayreg(bit"101"))
    r = join(r2, r1)
    @test measure(r) == [bit"101110"]
end
