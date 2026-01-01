using Test, YaoBlocks, YaoBlocks.ConstGate
using YaoBlocks: ErrorPattern, SimulationTask, AtLoc, parse_noise_model, CustomKrausError, ReadOutError

@testset "parse instruction" begin
    c1 = chain(1)
    pattern = ErrorPattern[]
    # single qubits gates
    @test Matrix(YaoBlocks.parse_instruction!(c1, "id", [1], [], pattern)[end]) ≈ [1 0; 0 1]
    @test Matrix(YaoBlocks.parse_instruction!(c1, "x", [1], [], pattern)[end]) ≈ [0 1; 1 0]
    @test Matrix(YaoBlocks.parse_instruction!(c1, "y", [1], [], pattern)[end]) ≈ [0 -im; im 0]
    @test Matrix(YaoBlocks.parse_instruction!(c1, "z", [1], [], pattern)[end]) ≈ [1 0; 0 -1]
    @test Matrix(YaoBlocks.parse_instruction!(c1, "h", [1], [], pattern)[end]) ≈ [1 1; 1 -1] / sqrt(2)
    @test Matrix(YaoBlocks.parse_instruction!(c1, "s", [1], [], pattern)[end]) ≈ [1 0; 0 im]
    @test Matrix(YaoBlocks.parse_instruction!(c1, "sdg", [1], [], pattern)[end]) ≈ [1 0; 0 -im]
    @test Matrix(YaoBlocks.parse_instruction!(c1, "t", [1], [], pattern)[end]) ≈ [1 0; 0 exp(im*pi/4)]
    @test Matrix(YaoBlocks.parse_instruction!(c1, "tdg", [1], [], pattern)[end]) ≈ [1 0; 0 exp(-im*pi/4)]
    @test Matrix(YaoBlocks.parse_instruction!(c1, "rx", [1], [0.5], pattern)[end]) ≈ [cos(0.5/2) -im*sin(0.5/2); -im*sin(0.5/2) cos(0.5/2)]
    @test Matrix(YaoBlocks.parse_instruction!(c1, "ry", [1], [0.5], pattern)[end]) ≈ [cos(0.5/2) -sin(0.5/2); sin(0.5/2) cos(0.5/2)]
    @test Matrix(YaoBlocks.parse_instruction!(c1, "rz", [1], [0.5], pattern)[end]) ≈ [exp(-im*0.5/2) 0; 0 exp(im*0.5/2)]
    # u1, u2, u3
    @test Matrix(YaoBlocks.parse_instruction!(c1, "u1", [1], [0.5], pattern)[end]) ≈ [1 0; 0 exp(im*0.5)]
    @test Matrix(YaoBlocks.parse_instruction!(c1, "u2", [1], [0.5, 0.6], pattern)[end]) ≈ [1 -exp(im*0.6); exp(im*0.5) exp(im*1.1)] ./ sqrt(2)
    @test Matrix(YaoBlocks.parse_instruction!(c1, "u3", [1], [0.3, 0.5, 0.6], pattern)[end]) ≈ [cos(0.3/2) -exp(im*0.6)*sin(0.3/2); exp(im*0.5)*sin(0.3/2) exp(im*1.1)*cos(0.3/2)]
    # sx and sxdg
    @test Matrix(YaoBlocks.parse_instruction!(c1, "sx", [1], [], pattern)[end]) ≈ [1+im 1-im; 1-im 1+im]/2
    # r
    @test Matrix(YaoBlocks.parse_instruction!(c1, "r", [1], [0.5, 0.6], pattern)[end]) ≈ [cos(0.5/2) -im*exp(-im*0.6)*sin(0.5/2); -im*exp(im*0.6)*sin(0.5/2) cos(0.5/2)]
    # two qubits gates
    c2 = chain(2)
    reorder(x) = reshape(permutedims(reshape(x, 2, 2, 2, 2), (2, 1, 4, 3)), 4, 4)
    @test Matrix(YaoBlocks.parse_instruction!(c2, "cx", [1, 2], [], pattern)[end]) ≈ reorder([1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 1 0])
    @test Matrix(YaoBlocks.parse_instruction!(c2, "cy", [1, 2], [], pattern)[end]) ≈ reorder([1 0 0 0; 0 1 0 0; 0 0 0 -im; 0 0 im 0])
    @test Matrix(YaoBlocks.parse_instruction!(c2, "cz", [1, 2], [], pattern)[end]) ≈ reorder([1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 -1])
    @test Matrix(YaoBlocks.parse_instruction!(c2, "ch", [1, 2], [], pattern)[end]) ≈ reorder([1 0 0 0; 0 1 0 0; 0 0 1/sqrt(2) 1/sqrt(2); 0 0 1/sqrt(2) -1/sqrt(2)])
    @test Matrix(YaoBlocks.parse_instruction!(c2, "crz", [1, 2], [0.5], pattern)[end]) ≈ reorder([1 0 0 0; 0 1 0 0; 0 0 exp(-im*0.5/2) 0; 0 0 0 exp(im*0.5/2)])
    # cu1 and cu3
    @test Matrix(YaoBlocks.parse_instruction!(c2, "cu1", [1, 2], [0.5], pattern)[end]) ≈ reorder([1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 exp(im*0.5)])
    @test Matrix(YaoBlocks.parse_instruction!(c2, "cu3", [1, 2], [0.3, 0.5, 0.6], pattern)[end]) ≈ reorder([1 0 0 0; 0 1 0 0; 0 0 cos(0.3/2) -exp(im*0.6)*sin(0.3/2); 0 0 exp(im*0.5)*sin(0.3/2) exp(im*1.1)*cos(0.3/2)])
    # rxx and rzz
    @test Matrix(YaoBlocks.parse_instruction!(c2, "rxx", [1, 2], [0.5], pattern)[end]) ≈ [cos(0.25) 0 0 -im*sin(0.25); 0 cos(0.25) -im*sin(0.25) 0; 0 -im*sin(0.25) cos(0.25) 0; -im*sin(0.25) 0 0 cos(0.25)]
    @test Matrix(YaoBlocks.parse_instruction!(c2, "rzz", [1, 2], [0.5], pattern)[end]) ≈ [exp(-im*0.25) 0 0 0; 0 exp(im*0.25) 0 0; 0 0 exp(im*0.25) 0; 0 0 0 exp(-im*0.25)]
    # swap
    @test Matrix(YaoBlocks.parse_instruction!(c2, "swap", [1, 2], [], pattern)[end]) ≈ [1 0 0 0; 0 0 1 0; 0 1 0 0; 0 0 0 1]

    # ccx
    c3 = chain(3)
    reorder3(x) = reshape(permutedims(reshape(x, 2, 2, 2, 2, 2, 2), (3, 2, 1, 6, 5, 4)), 8, 8)
    @test Matrix(YaoBlocks.parse_instruction!(c3, "ccx", [1, 2, 3], [], pattern)[end]) ≈ reorder3([1 0 0 0 0 0 0 0; 0 1 0 0 0 0 0 0; 0 0 1 0 0 0 0 0; 0 0 0 1 0 0 0 0; 0 0 0 0 1 0 0 0; 0 0 0 0 0 1 0 0; 0 0 0 0 0 0 0 1; 0 0 0 0 0 0 1 0])
end

@testset "parse instruction with noise" begin
    # different gates
    pattern = [
        ErrorPattern([[1]], ["id"], DepolarizingError(1, 0.01)),
        ErrorPattern([[1]], ["x"], DepolarizingError(1, 0.01)),
        ErrorPattern([[1]], ["y"], DepolarizingError(1, 0.01)),
        ErrorPattern([[1]], ["z"], DepolarizingError(1, 0.01)),
        ErrorPattern([[1]], ["h"], DepolarizingError(1, 0.01)),
        ErrorPattern([[1]], ["s"], DepolarizingError(1, 0.01)),
        ErrorPattern([[1]], ["sdg"], DepolarizingError(1, 0.01)),
        ErrorPattern([[1]], ["t"], DepolarizingError(1, 0.01)),
        ErrorPattern([[1]], ["tdg"], DepolarizingError(1, 0.01)),
        ErrorPattern([[1]], ["rx"], DepolarizingError(1, 0.01)),
        ErrorPattern([[1]], ["ry"], DepolarizingError(1, 0.01)),
        ErrorPattern([[1]], ["rz"], DepolarizingError(1, 0.01)),
        ErrorPattern([[1]], ["u1"], DepolarizingError(1, 0.01)),
        ErrorPattern([[1]], ["u2"], DepolarizingError(1, 0.01)),
        ErrorPattern([[1]], ["u3"], DepolarizingError(1, 0.01)),
        ErrorPattern([[1, 2]], ["cx"], DepolarizingError(2, 0.01)),
        ErrorPattern([[1, 2]], ["cy"], DepolarizingError(2, 0.01)),
        ErrorPattern([[1, 2]], ["cz"], DepolarizingError(2, 0.01)),
        ErrorPattern([[1, 2]], ["ch"], DepolarizingError(2, 0.01)),
        ErrorPattern([[1, 2]], ["crz"], DepolarizingError(2, 0.01)),
        ErrorPattern([[1, 2]], ["cu1"], DepolarizingError(2, 0.01)),
        ErrorPattern([[1, 2]], ["cu3"], DepolarizingError(2, 0.01)),
        ErrorPattern([[1, 2, 3]], ["ccx"], DepolarizingError(3, 0.01)),
    ]
    qasm_str = """
        OPENQASM 2.0;
        include "qelib1.inc";
        qreg q[3];
        creg c1[3];
        id q[0];
        x q[0];
        y q[0];
        z q[0];
        h q[0];
        s q[0];
        sdg q[0];
        t q[0];
        tdg q[0];
        rx(0.7) q[0];
        ry(0.7) q[0];
        rz(0.7) q[0];
        u1(0.7) q[0];
        u2(0.7, 0.8) q[0];
        u3(0.7, 0.8, 0.9) q[0];
        cx q[0],q[1];
        cy q[0],q[1];
        cz q[0],q[1];
        ch q[0],q[1];
        crz(0.7) q[0],q[1];
        cu1(0.7) q[0],q[1];
        cu3(0.7, 0.8, 0.9) q[0],q[1];
        ccx q[0],q[1],q[2];
        measure q[0] -> c1[0];
        measure q[1] -> c1[1];
        measure q[2] -> c1[2];    
    """
    ast = YaoBlocks.OpenQASM.parse(qasm_str)
    @test ast isa YaoBlocks.OpenQASM.Types.MainProgram
    task = parseblock(ast, pattern)
    @test length(task.circuit) == 49

    # at different locations
    pattern = [
        ErrorPattern([[1, 2]], ["cx"], DepolarizingError(2, 0.01)),
        ErrorPattern([[2]], ["x"], DepolarizingError(1, 0.01)),
        ErrorPattern([[2]], ["x"], PhaseDampingError(0.1)),
        ErrorPattern([[1]], ["x"], DepolarizingError(1, 0.01)),
        ErrorPattern([[1]], ["y"], DepolarizingError(1, 0.01)),
    ]
    qasm_str = """
        OPENQASM 2.0;
        include "qelib1.inc";
        qreg q[3];
        creg c1[3];
        x q[0];
        x q[1];
        y q[1];
        z q[2];
        cx q[0],q[1];
        cx q[1],q[0];
        measure q[0] -> c1[0];
        measure q[1] -> c1[1];
        measure q[2] -> c1[2];    
    """
    ast = YaoBlocks.OpenQASM.parse(qasm_str)
    task = parseblock(ast, pattern)
    @test task.circuit == chain(3,
        put(3, 1=>X),   # rule 4 match
        put(3, 1=>quantum_channel(DepolarizingError(1, 0.01))),

        put(3, 2=>X),   # rule 2,3 match
        put(3, 2=>quantum_channel(DepolarizingError(1, 0.01))),
        put(3, 2=>quantum_channel(PhaseDampingError(0.1))),

        put(3, 2=>Y),   # no rule match
        put(3, 3=>Z),   # no rule match

        control(3, 1, 2=>X),   # rule 4 match
        put(3, (1, 2)=>quantum_channel(DepolarizingError(2, 0.01))),

        control(3, 2, 1=>X),   # no rule match
        Measure(3; locs=1),
        Measure(3; locs=2),
        Measure(3; locs=3),
    )
end

@testset "parse" begin
    qasm_str = """
        OPENQASM 2.0;
        include "qelib1.inc";
        qreg q[3];
        creg c1[3];
        h q[0];
        CX q[1],q[2];
        cy q[1],q[0];
        cz q[0],q[2];
        x q[0];
        swap q[1],q[2];
        id q[0];
        t q[1];
        rz(0.7) q[2];
        z q[0];
        p(0.7) q[1];
        ry(0.7) q[2];
        y q[0];
        rx(0.7) q[1];
        measure q[0] -> c1[0];
        measure q[1] -> c1[1];
        measure q[2] -> c1[2];    
    """
    ast = YaoBlocks.OpenQASM.parse(qasm_str)
    @test ast isa YaoBlocks.OpenQASM.Types.MainProgram
end

@testset "parse block" begin
    qasm_str = """
        OPENQASM 2.0;
        include "qelib1.inc";
        qreg q[3];
        creg c1[3];
        h q[0];
        CX q[1],q[2];
        cy q[1],q[0];
        cz q[0],q[2];
        x q[0];
        swap q[1],q[2];
        id q[0];
        t q[1];
        rz(0.7) q[2];
        z q[0];
        ry(0.7) q[2];
        y q[0];
        rx(0.7) q[1];
        measure q[0] -> c1[0];
        measure q[1] -> c1[1];
        measure q[2] -> c1[2];    
    """
    task = parseblock(qasm_str)
    @test length(task.circuit) == 16
    @test length(task.outcomes) == 3
    @test task.outcomes[1] == Measure(3; locs=1)
    @test task.outcomes[2] == Measure(3; locs=2)
    @test task.outcomes[3] == Measure(3; locs=3)
end

@testset "parse with comments" begin
    qasm_str = """
OPENQASM 2.0;
include "qelib1.inc";
qreg q[4]; // claim a quantum register named 'q' with 4 qubits
creg c[4]; // claim a classical register named 'c' with 4 bits for measurement

x q[0]; 
x q[2];

h q[0];
cu1(pi/2) q[1],q[0];
h q[1];
cu1(pi/4) q[2],q[0];
cu1(pi/2) q[2],q[1];
h q[2];
cu1(pi/8) q[3],q[0];
cu1(pi/4) q[3],q[1];
cu1(pi/2) q[3],q[2];
h q[3];
measure q -> c;
"""
    ast = YaoBlocks.OpenQASM.parse(qasm_str)
    @test ast isa YaoBlocks.OpenQASM.Types.MainProgram
    task = parseblock(ast, ErrorPattern[])
    @test length(task.circuit) == 13
    @test length(task.outcomes) == 4
    @test task.outcomes[1] == AtLoc(Measure(4), 1)
    @test task.outcomes[2] == AtLoc(Measure(4), 2)
    @test task.outcomes[3] == AtLoc(Measure(4), 3)
    @test task.outcomes[4] == AtLoc(Measure(4), 4)
end

@testset "comprehensive noise parsing tests" begin
    
    @testset "depolarizing noise" begin
        noise_data = [Dict(
            "type" => "depolarizing",
            "operations" => ["ry"],
            "qubits" => [[0]],
            "probability" => 0.1
        )]
        gate_errors, ro_error = parse_noise_model(noise_data)
        @test length(gate_errors) == 1
        @test gate_errors[1].locs == [[1]]
        @test gate_errors[1].operations == ["ry"]
        @test gate_errors[1].error isa DepolarizingError
        @test gate_errors[1].error.p == 0.1
        @test ro_error isa Vector{ReadOutError}
    end
    
    @testset "depolarizing2 noise" begin
        noise_data = [Dict(
            "type" => "depolarizing2",
            "operations" => ["cx"],
            "qubits" => [[0, 1]],
            "probability" => 0.05
        )]
        gate_errors, ro_error = parse_noise_model(noise_data)
        @test length(gate_errors) == 1
        @test gate_errors[1].locs == [[1, 2]]
        @test gate_errors[1].operations == ["cx"]
        @test gate_errors[1].error isa DepolarizingError
        @test gate_errors[1].error.p == 0.05
    end
    
    @testset "thermal_relaxation noise" begin
        noise_data = [Dict(
            "type" => "thermal_relaxation",
            "operations" => ["u3"],
            "qubits" => [[0]],
            "T1" => 50000.0,
            "T2" => 70000.0,
            "time" => 100.0
        )]
        gate_errors, ro_error = parse_noise_model(noise_data)
        @test length(gate_errors) == 1
        @test gate_errors[1].error isa ThermalRelaxationError
        @test gate_errors[1].error.T1 == 50000.0
        @test gate_errors[1].error.T2 == 70000.0
        @test gate_errors[1].error.time == 100.0
    end
    
    @testset "coherent_unitary noise" begin
        noise_data = [Dict(
            "type" => "coherent_unitary",
            "operations" => ["u1"],
            "qubits" => [[0]],
            "unitary" => [[1.0, 0.0], [0.0, 1.0]]  # Identity matrix
        )]
        gate_errors, ro_error = parse_noise_model(noise_data)
        @test length(gate_errors) == 1
        @test gate_errors[1].error isa CoherentError
        @test gate_errors[1].error.block isa AbstractBlock
    end
    
    @testset "pauli noise" begin
        noise_data = [Dict(
            "type" => "pauli",
            "operations" => ["u2"],
            "qubits" => [[0]],
            "probability" => [0.01, 0.01, 0.01]  # X, Y, Z probabilities
        )]
        gate_errors, ro_error = parse_noise_model(noise_data)
        @test length(gate_errors) == 1
        @test gate_errors[1].error isa PauliError
        @test gate_errors[1].error.px == 0.01
        @test gate_errors[1].error.py == 0.01
        @test gate_errors[1].error.pz == 0.01
    end
    
    @testset "amplitude_damping noise" begin
        noise_data = [Dict(
            "type" => "amplitude_damping",
            "operations" => ["x"],
            "qubits" => [[0]],
            "gamma_amplitude" => 0.1,
            "excited_state_population" => 0.0
        )]
        gate_errors, ro_error = parse_noise_model(noise_data)
        @test length(gate_errors) == 1
        @test gate_errors[1].error isa AmplitudeDampingError
        @test gate_errors[1].error.amplitude == 0.1
        @test gate_errors[1].error.excited_state_population == 0.0
    end
    
    @testset "phase_damping noise" begin
        noise_data = [Dict(
            "type" => "phase_damping",
            "operations" => ["z"],
            "qubits" => [[0]],
            "gamma_phase" => 0.05
        )]
        gate_errors, ro_error = parse_noise_model(noise_data)
        @test length(gate_errors) == 1
        @test gate_errors[1].error isa PhaseDampingError
        @test gate_errors[1].error.phase == 0.05
    end
    
    @testset "phase_amplitude_damping noise" begin
        noise_data = [Dict(
            "type" => "phase_amplitude_damping",
            "operations" => ["y"],
            "qubits" => [[0]],
            "gamma_amplitude" => 0.1,
            "gamma_phase" => 0.05,
            "excited_state_population" => 0.0
        )]
        gate_errors, ro_error = parse_noise_model(noise_data)
        @test length(gate_errors) == 1
        @test gate_errors[1].error isa PhaseAmplitudeDampingError
        @test gate_errors[1].error.amplitude == 0.1
        @test gate_errors[1].error.phase == 0.05
        @test gate_errors[1].error.excited_state_population == 0.0
    end
    
    @testset "kraus noise" begin
        noise_data = [Dict(
            "type" => "kraus",
            "operations" => ["h"],
            "qubits" => [[0]],
            "kraus_ops" => [[[1.0, 0.0], [0.0, 1.0]], [[0.0, 1.0], [1.0, 0.0]]]  # Identity and X
        )]
        gate_errors, ro_error = parse_noise_model(noise_data)
        @test length(gate_errors) == 1
        @test gate_errors[1].error isa CustomKrausError
        @test length(gate_errors[1].error.kraus_ops) == 2
    end
    
    @testset "roerror (readout error)" begin
        noise_data = [Dict(
            "type" => "roerror",
            "operations" => ["measure"],
            "qubits" => [[0]],
            "probability" => [[0.8, 0.2], [0.1, 0.9]]
        )]
        gate_errors, ro_error = parse_noise_model(noise_data)
        @test length(gate_errors) == 0  # No gate errors for readout error
        @test ro_error isa Vector{ReadOutError}
        @test ro_error[1].probability == [[0.8, 0.2], [0.1, 0.9]]
    end
    
    @testset "mixed noise types" begin
        noise_data = [
            Dict(
                "type" => "depolarizing",
                "operations" => ["x"],
                "qubits" => [[0]],
                "probability" => 0.1
            ),
            Dict(
                "type" => "roerror",
                "operations" => ["measure"],
                "qubits" => [[0]],
                "probability" => [[0.9, 0.1], [0.05, 0.95]]
            )
        ]
        gate_errors, ro_error = parse_noise_model(noise_data)
        @test length(gate_errors) == 1
        @test gate_errors[1].error isa DepolarizingError
        @test ro_error[1].probability == [[0.9, 0.1], [0.05, 0.95]]
    end
    
    @testset "unknown noise type error" begin
        noise_data = [Dict(
            "type" => "unknown_noise",
            "operations" => ["x"],
            "qubits" => [[0]],
            "probability" => 0.1
        )]
        @test_throws ErrorException parse_noise_model(noise_data)
    end
end

@testset "partial measurement" begin
    qasm_str = """
    OPENQASM 2.0;
    include "qelib1.inc";
    qreg q[3];
    creg c[1];
    measure q[2] -> c[0];
    """
    ast = YaoBlocks.OpenQASM.parse(qasm_str)
    @test ast isa YaoBlocks.OpenQASM.Types.MainProgram
    task = parseblock(ast, ErrorPattern[])
    @test task.outcomes[1] == Measure(3; locs=3)
end

@testset "negative angles" begin
    qasm_str = """
    OPENQASM 2.0;
    include "qelib1.inc";
    qreg q[1];

    ry(-1.44734) q[0];
    h q[0];

    creg c[1];
    measure q -> c;
    """
    ast = YaoBlocks.OpenQASM.parse(qasm_str)
    @test ast isa YaoBlocks.OpenQASM.Types.MainProgram
    task = parseblock(ast, ErrorPattern[])
    @test task isa SimulationTask
end
