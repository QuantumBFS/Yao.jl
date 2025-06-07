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