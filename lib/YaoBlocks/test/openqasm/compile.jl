using Test, YaoBlocks, YaoBlocks.ConstGate

@testset "primitive blocks" begin
    @test qasm(I2) == "id"
    @test qasm(X) == "x"
    @test qasm(Y) == "y"
    @test qasm(Z) == "z"
    @test qasm(S) == "s"
    @test qasm(T) == "t"
    @test qasm(Sdag) == "inv @ s"
    @test qasm(Tdag) == "inv @ t"
    @test qasm(Rx(0.7)) == "rx(0.7)"
    @test qasm(Ry(0.7)) == "ry(0.7)"
    @test qasm(Rz(0.7)) == "rz(0.7)"

    # customized gate
    @test qasm(matblock(rand_unitary(4); tag="zz")) == "zz"

    # phase gate
    @test qasm(shift(0.7)) == "p(0.7)"

    # undefined gate
    @const_gate UU = rand_unitary(4)
    @test_throws ErrorException qasm(UU)
end

@testset "put block" begin
    # note qubit index of OpenQASM is 0-based
    @test qasm(put(6, 5=>X)) == "x q[4]"
end

@testset "control block" begin
    # QASM 2.0 compatible gates
    @test qasm(control(6, 3, 5=>X)) == "cx q[2], q[4]"
    @test qasm(control(6, 3, 5=>Y)) == "cy q[2], q[4]"
    @test qasm(control(6, 3, 5=>Z)) == "cz q[2], q[4]"
    @test qasm(control(6, 3, 5=>H)) == "ch q[2], q[4]"
    @test qasm(control(6, 3, 5=>shift(0.5))) == "cu1(0.5) q[2], q[4]"
    @test qasm(control(6, 3, 5=>Rz(0.5))) == "crz(0.5) q[2], q[4]"

    # Toffoli gate
    @test qasm(control(6, (2, 3), 5=>X)) == "ccx q[1], q[2], q[4]"

    # Fallback to QASM 3.0 syntax for negative controls
    @test qasm(control(6, -3, 5=>X)) == "negctrl @ x q[2], q[4]"
    @test qasm(control(6, (-3, 2), 5=>X)) == "negctrl @ ctrl @ x q[2], q[1], q[4]"

    # cphase with negative control (fallback)
    @test qasm(control(6, (-3, 2), 5=>shift(0.5))) == "negctrl @ ctrl @ p(0.5) q[2], q[1], q[4]"
end

@testset "chain block" begin
    @test qasm(chain(put(6, 5=>X))) == "x q[4];\n"
    @test qasm(chain(put(6, 5=>X), put(6, 3=>X))) == "x q[4];\nx q[2];\n"
    expected = "OPENQASM 2.0;\ninclude \"qelib1.inc\";\nqreg q[6];\ncreg c[6];\nx q[4];\nx q[2];\n"
    @test qasm(chain(put(6, 5=>X), put(6, 3=>X)); include_header=true) == expected
    @test_throws AssertionError qasm(chain(X, Y))

    # nested chain blocks (no extra semicolons)
    nested = chain(2, chain(put(2, 1=>X), put(2, 2=>Y)), chain(put(2, 1=>Z)))
    @test qasm(nested) == "x q[0];\ny q[1];\nz q[0];\n"
end

@testset "dagger block" begin
    @test qasm(Daggered(put(6, 5=>X))) == "inv @ x q[4]"
end

@testset "compile-parse roundtrip" begin
    using YaoBlocks.YaoArrayRegister: fidelity, rand_state

    # Test roundtrip for various circuits
    circuits = [
        # Simple gates
        chain(2, put(1=>H), put(2=>X)),
        # Controlled gates
        chain(2, put(1=>H), control(1, 2=>X)),
        # Controlled phase
        chain(3, put(1=>H), control(2, 1=>shift(π/4)), control(3, 1=>shift(π/8))),
        # Toffoli
        chain(3, put(1=>H), control((1, 2), 3=>X)),
        # Rotation gates
        chain(2, put(1=>Rx(0.5)), put(2=>Ry(0.7)), put(1=>Rz(0.3))),
    ]

    for (i, circuit) in enumerate(circuits)
        qasm_str = qasm(circuit; include_header=true)
        task = parseblock(qasm_str)
        parsed = task.circuit

        # Test functional equivalence
        n = nqubits(circuit)
        reg1 = rand_state(n)
        reg2 = copy(reg1)
        apply!(reg1, circuit)
        apply!(reg2, parsed)
        @test fidelity(reg1, reg2) ≈ 1.0 atol=1e-10
    end
end
