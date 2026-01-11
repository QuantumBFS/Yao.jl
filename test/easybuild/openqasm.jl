using Test, Yao, Yao.EasyBuild

@testset "qft_circuit roundtrip" begin
    for n in 2:5
        circuit = qft_circuit(n)
        qasm_str = qasm(circuit; include_header=true)
        task = parseblock(qasm_str)
        parsed = task.circuit

        # Test functional equivalence using fidelity
        reg1 = rand_state(n)
        reg2 = copy(reg1)
        apply!(reg1, circuit)
        apply!(reg2, parsed)
        @test fidelity(reg1, reg2) ≈ 1.0 atol=1e-10
    end
end

@testset "variational_circuit roundtrip" begin
    for n in 2:4
        circuit = variational_circuit(n, 2)
        qasm_str = qasm(circuit; include_header=true)
        task = parseblock(qasm_str)
        parsed = task.circuit

        # Test functional equivalence using fidelity
        reg1 = rand_state(n)
        reg2 = copy(reg1)
        apply!(reg1, circuit)
        apply!(reg2, parsed)
        @test fidelity(reg1, reg2) ≈ 1.0 atol=1e-10
    end
end
