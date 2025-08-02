using YaoBlocks, YaoArrayRegister, Test

@testset "SuperOp" begin
    so = SuperOp{2}(1, [1 0 0 0; 0 0 1 0; 0 1 0 0; 0 0 0 1])
    println(so)
    @test occupied_locs(so) == (1,)
    @test so isa SuperOp{2}
    @test nqudits(so) == 1
    so2 = copy(so)
    @test so == so2
end

@testset "apply" begin
    # single qubit
    for op in [X, Y, ConstGate.T]
        @info "Testing $op"
        so = SuperOp(op)
        reg = rand_state(1)
        rho = density_matrix(reg)
        res_reg = apply(reg, op)
        res_rho = apply(rho, so)
        @test density_matrix(res_reg) ≈ res_rho
    end

    # multi-qubit
    n = 5
    for (k, op0) in [(2, X), (3, Y), (4, T), ((3, 1), cnot(2, 2, 1))]
        op = put(n, k=>op0)
        @info "Testing $op"
        so = put(n, k=>SuperOp(op0))
        reg = rand_state(n)
        rho = density_matrix(reg)
        res_reg = apply(reg, op)
        res_rho = apply(rho, so)
        @test density_matrix(res_reg) ≈ res_rho
    end

    # composed
    n = 3
    mb = matblock(rand(ComplexF64, 2^n, 2^n))
    c1 = chain(n, put(n, 1=>X), put(n, 3=>SuperOp(T)), SuperOp(mb), kron(X, Y, SuperOp(T)), repeat(n, SuperOp(X)))
    c2 = chain(n, put(n, 1=>X), put(n, 3=>T), mb, kron(X, Y, T), repeat(n, X))
    reg = rand_state(n)
    rho = density_matrix(reg)
    res_reg = apply(reg, c2)
    res_rho = apply(rho, c1)
    res_rho2 = apply(rho, c2)
    @test density_matrix(res_reg) ≈ res_rho2
    @test density_matrix(res_reg) ≈ res_rho
end

@testset "noisy superop" begin
    n = 3
    c_noisy = chain(n, put(n, 1=>chain(Z, quantum_channel(BitFlipError(0.1)))))
    sp = chain(n, put(n, 1=>SuperOp(chain(Z, quantum_channel(BitFlipError(0.1))))))
    reg = rand_state(n)
    rho = density_matrix(reg)
    res_rho = apply(rho, c_noisy)
    res_rho2 = apply(rho, sp)
    @test res_rho ≈ res_rho2
end