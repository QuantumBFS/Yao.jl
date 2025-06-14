using Test, YaoBlocks, YaoArrayRegister

@testset "KrausChannel" begin
    op1 = matblock(rand_unitary(2))
    op2 = matblock(rand_unitary(2))
    kraus_channel = KrausChannel([op1, op2])
    @test kraus_channel.n == 1
    @test kraus_channel.operators == [op1, op2]
end

@testset "KrausChannel apply" begin
    n_qubits = 4
    circ = chain(
        put(n_qubits, 1 => H),
        put(n_qubits, 1 => KrausChannel(PhaseFlipError(0.1))),
        put(n_qubits, 1 => H),
    )
    rho = apply(density_matrix(zero_state(n_qubits)), circ)
    samples = measure(rho, nshots=1000)
    res = [(i => count(==(i), samples)) for i in unique(samples)]
    @test length(res) == 2
    if res[1].first == bit"0000"
        @test 850 < res[1][2] < 950  # the expected probability is 0.9
    else
        @test 850 < res[2][2] < 950  # the expected probability is 0.9
    end
end

@testset "kron" begin
    n_qubits = 3
    op1 = matblock(rand_unitary(2))
    op2 = matblock(rand_unitary(2))
    kraus_channel = KrausChannel([op1, op2])
    kraus_channel2 = KrausChannel([op1, op2])
    kraus_channel3 = kron(kraus_channel, kraus_channel2)

    circ1 = chain(n_qubits, put(n_qubits, 1 => kraus_channel), put(n_qubits, 2 => kraus_channel2))
    circ2 = chain(n_qubits, put(n_qubits, (1, 2) => kraus_channel3))

    reg = rand_state(n_qubits)
    @test noisy_simulation(reg, circ1) ≈ noisy_simulation(reg, circ2)
end

@testset "direct apply" begin
    n_qubits = 1
    c = KrausChannel(PhaseFlipError(0.1))
    mu = MixedUnitaryChannel([I2, X], [0.9, 0.1])
    so = SuperOp(rand_unitary(4))
    g = chain(1, c, mu, so)
    reg = density_matrix(rand_state(n_qubits))
    @test apply(reg, g) isa DensityMatrix
end

@testset "noisy_instruct!" begin
    n_qubits = 3
    c = KrausChannel(PhaseFlipError(0.1))
    g1 = chain(3, put(3, 1=>c))
    g1x = MixedUnitaryChannel([igate(3), put(3, 1=>Z)], [0.9, 0.1])
    g2 = put(3, (2,1)=>put(2, 1=>c))  # nested put
    g2x = MixedUnitaryChannel([igate(3), put(3, 2=>Z)], [0.9, 0.1])
    g3 = put(3, (2,1)=>put(2, 1=>chain(X, c, X)))  # nested put and chain
    g3x = chain(3, put(3, 2=>X), MixedUnitaryChannel([igate(3), put(3, 2=>Z)], [0.9, 0.1]), put(3, 2=>X))
    g4 = chain(3, put(3, 1=>c), put(3, (2,1)=>kron(chain(X, c, X), X)))  # nested put and chain, and kron
    g4x = chain(3, g1x, put(3, (2,1)=>kron(X, X)), g2x, put(3, 2=>X))
    g5 = chain(3, put(3, 1=>c) + 2*put(3, (2,1)=>kron(chain(X, c, X), X)))  # nested put and chain, and kron, and add, and scale
    g6 = chain(3, put(3, 1=>c), put(3, (2,1)=>kron(chain(X, c, X), X)))'  # nested put and chain, and kron, and adjoint
    g6x = g4x
    for g in [g1, g2, g3, g4, g5, g6]
        reg = density_matrix(rand_state(n_qubits))
        sg = standardize(g)
        @test apply(reg, g) ≈ apply(reg, sg)
    end
    for (i, (g1, g2)) in enumerate(zip([g1x, g2x, g3x, g4x, g6x], [g1, g2, g3, g4, g6]))
        @info "Testing $i: $g1 and $g2"
        reg = density_matrix(rand_state(n_qubits))
        @test apply(reg, g1) ≈ apply(reg, g2)
    end
end