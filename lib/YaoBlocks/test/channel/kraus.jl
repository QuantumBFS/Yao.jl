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
    @test 850 < res[1][2] < 950  # the expected probability is 0.9
end