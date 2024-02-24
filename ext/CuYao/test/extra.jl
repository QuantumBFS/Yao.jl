using Yao, Test, CUDA
CUDA.allowscalar(false)

@testset "gradient" begin
    reg1 = rand_state(10)
    reg2 = rand_state(10)
    c = EasyBuild.variational_circuit(10)
    g1, g2 = fidelity'(reg1=>c, reg2)
    cg1, cg2 = fidelity'(cu(reg1)=>c, cu(reg2))
    @test g1.first ≈ cpu(cg1.first)
    @test g1.second ≈ cg1.second
    @test g2 ≈ cpu(cg2)

    h = EasyBuild.heisenberg(10)
    g1 = expect'(h, reg1=>c)
    cg1 = expect'(h, cu(reg1)=>c)
    @test g1.first ≈ cpu(cg1.first)
    @test g1.second ≈ cg1.second
end

@testset "apply density matrix" begin
    reg = rand_state(6)
    creg = cu(reg)
    rho = density_matrix(reg, (3,4))
    crho = density_matrix(creg, (3,4))
    @test rho ≈ cpu(crho)
    g = put(2, 1=>Rx(0.3))
    @test cpu(apply(crho, g)) ≈ apply(rho, g)
    rho = density_matrix(reg)
    crho = density_matrix(creg)
    @test rho ≈ cpu(crho)
    @test probs(crho) ≈ probs(creg)
    g = put(6, 1=>Rx(0.3))
    @test cpu(apply(crho, g)) ≈ apply(rho, g)

    # channel
    c = UnitaryChannel([put(6, 1=>Rx(0.3)), put(6, 2=>Z)], [0.4, 0.6])
    @test cpu(apply(crho, c)) ≈ apply(rho, c)
end

@testset "expect on density matrix" begin
    reg = rand_state(6)
    rho = density_matrix(reg, (3,4,5))
    crho = cu(rho)
    h = EasyBuild.heisenberg(3)
    a = expect(h, rho)
    b = expect(h, crho)
    @test a ≈ b
    # fidelity
    @test fidelity(crho, crho) ≈ 1
    @test measure(crho; nshots=2) isa Vector
end
