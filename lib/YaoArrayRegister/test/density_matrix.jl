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

@testset "test fidelity2" begin
    reg = rand_state(3)
    reg_ = rand_state(3)
    reg2 = clone(reg, 3)
    @test fidelity2(reg, reg) ≈ 1
    @test fidelity2(reg, reg_) < 1
    @test fidelity2(reg2, reg2) ≈ [1, 1, 1]
    @test isapprox(fidelity2(reg, reg_), fidelity(reg, reg_)^2)
    # mix
    reg4 = join(reg, reg)
    reg5 = join(reg_, reg_)
    focus!(reg4, 1:3)
    focus!(reg5, 1:3)
    @test isapprox(fidelity2(reg, reg_), fidelity2(reg4, reg5), atol = 1e-5)
    @test isapprox(fidelity2(reg4, reg5), fidelity(reg4, reg5)^2)

    @test isapprox.(
        fidelity2(reg, reg_),
        fidelity2(clone(reg4, 3), clone(reg5, 3)),
        atol = 1e-5,
    ) |> all

    @test isapprox.(
        fidelity2(clone(reg4, 3), clone(reg5, 3)),
        fidelity(clone(reg4, 3), clone(reg5, 3)).^2,
    ) |> all

    # batch
    st = rand(ComplexF64, 8, 2)
    reg1 = BatchedArrayReg(st)
    reg2 = rand_state(3)

    @test fidelity2(reg1, reg2) ≈
          [fidelity2(ArrayReg(st[:, 1]), reg2), fidelity2(ArrayReg(st[:, 2]), reg2)]
    @test isapprox(fidelity2(reg1, reg2), fidelity(reg1, reg2).^2)

    @test isapprox.(
        fidelity2(reg, reg_),
        fidelity2(clone(reg4, 3), clone(reg5, 3)),
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
    reg = ghz_state(4)
    rdm = density_matrix(reg, (1,))
    @test Matrix(rdm) ≈ [1/2 0; 0 1/2]
    reg = product_state([1, 0, 0])
    rdm = density_matrix(reg, (1, 2))
    @test Matrix(rdm) ≈ [0 0 0 0; 0 1 0 0; 0 0 0 0; 0 0 0 0]
end

@testset "von_neumann_entropy" begin
    reg = ghz_state(4)
    rho = density_matrix(reg)
    p = eigvals(statevec(reg) * statevec(reg)')
    p = max.(p, eps(Float64))
    @test von_neumann_entropy(rho) ≈ -sum(p .* log.(p)) rtol=1e-12

    rho = density_matrix(reg, 1:2)
    @test von_neumann_entropy(rho) ≈ log(2)
    @test von_neumann_entropy(rho) ≈ von_neumann_entropy(reg, 1:2)
end

@testset "mutual_information" begin 
    reg = product_state(bit"1001")
    @test mutual_information(reg, (1,2), (3,4)) ≈ 0. atol=1e-10
    rho = density_matrix(reg, 1:2)
    @test mutual_information(rho, (1,), (2,)) ≈ 0. atol=1e-10

    reg = ghz_state(4)
    @test mutual_information(reg, (1,2), (3,4)) ≈ 2log(2)
    @test_throws LocationConflictError mutual_information(reg, (1, 2), (1, 3))
    
    rho = density_matrix(reg, (1, 2))
    @test mutual_information(rho, (1,), (2,)) ≈ log(2)
end

@testset "relative and cross_entropy" begin 
    rho = rand_density_matrix(2)
    @test YaoArrayRegister.cross_entropy(rho, rho) ≈ von_neumann_entropy(rho) atol=1e-10

    rho1 = density_matrix(product_state(bit"0"))
    rho1.state[2,2] += eps(Float64)
    rho2 = density_matrix(ghz_state(2), (1,))
    @test YaoArrayRegister.relative_entropy(rho, rho) ≈ 0 atol=1e-10
    @test YaoArrayRegister.relative_entropy(rho1, rho2) ≈ log(2) atol=1e-10
    @test YaoArrayRegister.relative_entropy(rho2, rho1) ≈ -log(eps(Float64))/2 - von_neumann_entropy(rho2) atol=1e-10
end

@testset "density matrix" begin
    # copy, copyto! and similar
    reg = rand_state(3)
    r = density_matrix(reg)
    @test copy(r) == r
    @test density_matrix(r) == r


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
    r1 = density_matrix(reg1, (2, 1))
    r2 = density_matrix(reg2, (2, 1))
    expected = abs(tr(sqrt(sqrt(r1.state) * r2.state * sqrt(r1.state))))
    @test expected ≈ fidelity(r1, r2) atol=1e-5
    @test expected^2 ≈ fidelity2(r1, r2) atol=1e-5
    # focused state is viewed as mixed state
    f1 = focus!(copy(reg1), (2, 1))
    f2 = focus!(copy(reg2), (2, 1))
    @test fidelity(r1, r2) ≈ fidelity(f1, f2) atol=1e-6
    @test fidelity2(r1, r2) ≈ fidelity2(f1, f2) atol=1e-6
    @test fidelity2(r1, r2) ≈ fidelity(f1, f2)^2 atol=1e-6
    # fidelity between focused and pure state
    f1 = rand_state(2)
    @test fidelity(density_matrix(f1, (1, 2)), r2) ≈ fidelity(f1, f2) atol=1e-6
    @test fidelity2(density_matrix(f1, (1, 2)), r2) ≈ fidelity2(f1, f2) atol=1e-6
    @test fidelity2(density_matrix(f1, (1, 2)), r2) ≈ fidelity(f1, f2)^2 atol=1e-6

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
    @test dm.state == I(4) ./ 4
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

@testset "collapseto!" begin
    r = density_matrix(ghz_state(3))
    collapseto!(r, (1, 2) => (0, 0))
    res = measure(r; nshots=1000)
    @test all(==(bit"000"), res)
    @test isnormalized(r)
end

@testset "collapseto! with mixed states" begin
    rho = rand_density_matrix(8)
    collapseto!(rho, (5:8) => zeros(Int,4))  
    @test tr(rho.state) ≈ 1
end


@testset "measure on subset of qubits" begin
    r1 = density_matrix(arrayreg(bit"110"))
    r2 = density_matrix(arrayreg(bit"101"))
    r = join(r2, r1)
    @test measure(r, (1, 2)) == [bit"10"]
end

@testset "measure on density matrix, collapse" begin
    # AllLocs
    reg = ghz_state(3)
    rho = density_matrix(reg)
    res = measure!(rho)
    res2 = measure(rho; nshots=10)
    @test all(==(res), res2)

    # specific locs
    reg = ghz_state(3)
    rho = density_matrix(reg, (1, 2))
    res = measure!(rho, (1, 2))
    res2 = measure(rho, (1, 2); nshots=10)
    @test all(==(res), res2)
end


@testset "measure on density matrix, reset" begin
    # AllLocs
    reg = uniform_state(3)
    rho = density_matrix(reg)
    res = measure!(ResetTo(bit"110"), rho)
    res2 = measure(rho; nshots=10)
    @test all(==(bit"110"), res2)

    # specific locs
    reg = uniform_state(5)
    rho = density_matrix(reg, (1, 2, 3))
    res = measure!(ResetTo(bit"10"), rho, (1, 2))
    res2 = measure(rho, (1, 2); nshots=10)
    @test all(==(bit"10"), res2)
end

@testset "measure on density matrix, remove" begin
    # AllLocs
    reg = uniform_state(3)
    rho = density_matrix(reg, (1, 2))
    res = measure!(RemoveMeasured(), rho)
    @test nqubits(rho) == 0
    @test isnormalized(rho)

    # specific locs
    reg = uniform_state(5)
    rho = density_matrix(reg, (1, 2, 3))
    res = measure!(RemoveMeasured(), rho, (1, 2))
    @test nqubits(rho) == 1
    @test isnormalized(rho)
end
