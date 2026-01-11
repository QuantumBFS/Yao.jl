"""
    ErrorPattern

A pattern of error for noise simulation.

# Fields
- `locs::Vector{Vector{Int}}`: The locations of the error. The locations are nested vectors, and is 1-based.
- `operations::Vector{String}`: The operations of the error.
- `error::AbstractErrorType`: The error type.
"""
struct ErrorPattern
    locs::Vector{Vector{Int}}
    operations::Vector{String}
    error::AbstractErrorType
end

"""
    SimulationTask

A simulation task containing a circuit and outcomes.

# Fields
- `circuit::AbstractBlock`: The circuit to simulate
- `outcomes::Vector{Any}`: The measurement outcome references
"""
struct SimulationTask
    circuit::AbstractBlock
    outcomes::Vector{Any}
end

"""
    AtLoc{MT<:Measure}

A reference to a specific measurement location.

# Fields
- `ref::MT`: The measurement reference
- `i::Int`: The index within the measurement
"""
struct AtLoc{MT<:Measure}
    ref::MT
    i::Int
end
Base.:(==)(a::AtLoc, b::AtLoc) = a.ref == b.ref && a.i == b.i

"""
    parseblock(qasm::String, gate_error::Vector{ErrorPattern}=ErrorPattern[]) -> SimulationTask

Parse an OpenQASM 2.0 string into a YaoBlocks circuit.

# Arguments
- `qasm::String`: The OpenQASM string to parse
- `gate_error::Vector{ErrorPattern}=ErrorPattern[]`: Optional error patterns for noisy simulation

# Returns
- `SimulationTask`: Contains `.circuit` (the quantum circuit) and `.outcomes` (measurement references)

# Supported Gates
- **Single-qubit**: `id`, `x`, `y`, `z`, `h`, `s`, `sdg`, `t`, `tdg`, `sx`
- **Rotations**: `rx(θ)`, `ry(θ)`, `rz(θ)`, `r(θ,ϕ)`
- **U gates**: `u1(λ)`/`p(λ)`, `u2(ϕ,λ)`, `u3(θ,ϕ,λ)`
- **Two-qubit**: `cx`, `cy`, `cz`, `ch`, `swap`, `crz(θ)`, `cu1(λ)`/`cp(λ)`, `cu3(θ,ϕ,λ)`, `rxx(θ)`, `rzz(θ)`
- **Three-qubit**: `ccx` (Toffoli)
- **Measurement**: `measure q -> c;` or `measure q[i] -> c[j];`

# Notes
- Only `include "qelib1.inc"` is supported for include statements
- `qreg` and `creg` declarations must appear before gates
- Barriers are ignored with a warning
- QASM uses 0-based indexing; this is automatically converted to 1-based for YaoBlocks

# Examples

```jldoctest; setup=:(using Yao)
julia> qasm_str = \"\"\"
       OPENQASM 2.0;
       include "qelib1.inc";
       qreg q[2];
       creg c[2];
       h q[0];
       cx q[0],q[1];
       measure q -> c;
       \"\"\";

julia> task = parseblock(qasm_str);

julia> nqubits(task.circuit)
2

julia> task.circuit
nqubits: 2
chain
├─ put on (1)
│  └─ H
├─ control(1)
│  └─ (2,) X
└─ Measure(2)
```

See also: [`qasm`](@ref)
"""
function parseblock(qasm::String, gate_error::Vector{ErrorPattern}=ErrorPattern[])
    ast = OpenQASM.parse(qasm)
    parseblock(ast, gate_error)
end

# parse block from AST
function parseblock(ast::OpenQASM.Types.MainProgram, gate_error::Vector{ErrorPattern})
    c = nothing
    outcomes = nothing
    for stmt in ast.prog
        if stmt isa OpenQASM.Types.GateDecl
            not_supported_error(stmt)
        elseif stmt isa OpenQASM.Types.Gate
            not_supported_error(stmt)
        elseif stmt isa OpenQASM.Types.Instruction
            parse_instruction!(c, stmt.name, parse_location.(stmt.qargs), parsenode.(stmt.cargs), gate_error)
        elseif stmt isa OpenQASM.Types.Include
            @assert convert(String, stmt.file) == "qelib1.inc" "Only `qelib1.inc` is supported to be included. Got: $(convert(String, stmt.file))"
        elseif stmt isa OpenQASM.Types.RegDecl
            if convert(String, stmt.type) == "qreg"
                @assert c === nothing "The `qreg` register has already been declared. Only one quantum register declaration is allowed per QASM program."
                c = chain(convert(Int, stmt.size))
            elseif convert(String, stmt.type) == "creg"
                @assert outcomes === nothing "The `creg` register has already been declared. Only one classical register declaration is allowed per QASM program."
                outcomes = Vector{Any}(undef, convert(Int, stmt.size))
            else
                error("Unsupported register type: $(stmt.type)")
            end
        elseif stmt isa OpenQASM.Types.Barrier
            @warn "Barrier is ignored. got: $stmt"
        elseif stmt isa OpenQASM.Types.Reset
            not_supported_error(stmt)
        elseif stmt isa OpenQASM.Types.IfStmt
            not_supported_error(stmt)
        elseif stmt isa OpenQASM.Types.Measure
            loc = parse_location(stmt.qarg)
            cloc = parse_location(stmt.carg)
            cloc = cloc isa AllLocs ? (1:length(outcomes)) : cloc
            m = Measure(nqubits(c); locs=loc)
            if loc isa AllLocs
                for i in 1:nqubits(c)
                    outcomes[cloc[i]] = AtLoc(m, i)
                end
            else
                outcomes[cloc] = m
            end
            push!(c, m)
        elseif stmt isa OpenQASM.Types.Opaque
            not_supported_error(stmt)
        elseif stmt isa OpenQASM.Types.Neg
            not_supported_error(stmt)
        elseif stmt isa OpenQASM.Types.Bit
            not_supported_error(stmt)
        elseif stmt isa OpenQASM.Types.Call
            not_supported_error(stmt)
        elseif stmt isa OpenQASM.Types.CXGate
            ctrl_loc = parse_location(stmt.ctrl)
            qarg_loc = parse_location(stmt.qarg)
            push!(c, control(nqubits(c), ctrl_loc, qarg_loc => X))
            # Add noise for CX gates
            add_noise!(c, "cx", [ctrl_loc, qarg_loc], gate_error)
        elseif stmt isa OpenQASM.Types.UGate
            not_supported_error(stmt)
        else
            not_supported_error(stmt)
        end
    end
    return SimulationTask(c, outcomes)
end

function not_supported_error(stmt)
    error("Statement type not supported: $stmt of type $(typeof(stmt)), with fields: $(fieldnames(typeof(stmt)))")
end

# Ref: https://github.com/Qiskit/qiskit/blob/main/qiskit/qasm/libs/qelib1.inc
function parse_instruction!(c::ChainBlock, name, qargs, cargs, gate_error::Vector{ErrorPattern})
    n = nqubits(c)
    if name == "id"
        push!(c, put(n, qargs[1] => I2))
    elseif name == "x"
        push!(c, put(n, qargs[1] => X))
    elseif name == "y"
        push!(c, put(n, qargs[1] => Y))
    elseif name == "z"
        push!(c, put(n, qargs[1] => Z))
    elseif name == "h"
        push!(c, put(n, qargs[1] => H))
    elseif name == "s"
        push!(c, put(n, qargs[1] => ConstGate.S))
    elseif name == "r"
        θ, ϕ = cargs
        push!(c, put(n, qargs[1] => matblock([cos(θ/2) -im*exp(-im*ϕ)*sin(θ/2); -im*exp(im*ϕ)*sin(θ/2) cos(θ/2)]; tag="r")))
    elseif name == "sdg"
        push!(c, put(n, qargs[1] => ConstGate.Sdag))
    elseif name == "sx"
        # sqrt(X)
        push!(c, put(n, qargs[1] => matblock([1+im 1-im; 1-im 1+im]/2; tag="sx")))
    elseif name == "t"
        push!(c, put(n, qargs[1] => T))
    elseif name == "tdg"
        push!(c, put(n, qargs[1] => ConstGate.Tdag))
    elseif name == "rx"
        push!(c, put(n, qargs[1] => Rx(cargs[1])))
    elseif name == "ry"
        push!(c, put(n, qargs[1] => Ry(cargs[1])))
    elseif name == "rz"
        push!(c, put(n, qargs[1] => Rz(cargs[1])))
    elseif name == "u1" || name == "p"
        λ = cargs[1]
        push!(c, put(n, qargs[1] => shift(λ)))
    elseif name == "u2"
        ϕ, λ = cargs
        push!(c, put(n, qargs[1] => matblock([1 -exp(im*λ); exp(im*ϕ) exp(im * (ϕ + λ))] / sqrt(2); tag="u2")))
    elseif name == "u3"
        θ, ϕ, λ = cargs
        push!(c, put(n, qargs[1] => matblock([cos(θ/2) -exp(im*λ)*sin(θ/2); exp(im*ϕ)*sin(θ/2) exp(im * (ϕ + λ))*cos(θ/2)]; tag="u3")))
    elseif name == "cx"
        push!(c, control(n, qargs[1], qargs[2] => X))
    elseif name == "cy"
        push!(c, control(n, qargs[1], qargs[2] => Y))
    elseif name == "cz"
        push!(c, control(n, qargs[1], qargs[2] => Z))
    elseif name == "ch"
        push!(c, control(n, qargs[1], qargs[2] => H))
    elseif name == "ccx"
        push!(c, control(n, (qargs[1], qargs[2]), qargs[3] => X))
    elseif name == "crz"
        push!(c, control(n, qargs[1], qargs[2] => Rz(cargs[1])))
    elseif name == "rxx"
        push!(c, put(n, (qargs[1], qargs[2]) => rot(kron(X, X), cargs[1])))
    elseif name == "rzz"
        push!(c, put(n, (qargs[1], qargs[2]) => rot(kron(Z, Z), cargs[1])))
    elseif name == "swap"
        push!(c, swap(n, qargs[1], qargs[2]))
    elseif name == "cu1" || name == "cp"
        push!(c, control(n, qargs[1], qargs[2] => shift(cargs[1])))
    elseif name == "cu3"
        θ, ϕ, λ = cargs
        push!(c, control(n, qargs[1], qargs[2] => matblock([cos(θ/2) -exp(im*λ)*sin(θ/2); exp(im*ϕ)*sin(θ/2) exp(im * (ϕ + λ))*cos(θ/2)]; tag="u3")))
    else
        error("Unsupported instruction: $name")
    end
    
    # Add noise after each gate
    add_noise!(c, name, qargs, gate_error)
    return c
end

function add_noise!(c::ChainBlock, gate_name::String, qargs, gate_error::Vector{ErrorPattern})
    for error_pattern in gate_error
        if gate_name in error_pattern.operations
            @assert all(loc -> length(loc) == length(qargs), error_pattern.locs) "The number of qubits in the gate ($gate_name) and the error pattern must match. Got: $(length(qargs)) and $(length.(error_pattern.locs))"
            if qargs in error_pattern.locs
                push!(c, put(nqubits(c), Tuple(qargs) => quantum_channel(error_pattern.error)))
            end
        end
    end
end

function parsenode(t::OpenQASM.RBNF.Token{:float64})
    return convert(Float64, t)
end
function parsenode(t::OpenQASM.RBNF.Token{:int})
    return convert(Int, t)
end
function parsenode(t::OpenQASM.RBNF.Token{:id})
    return convert(String, t)
end
function parsenode(t::OpenQASM.RBNF.Token{:reserved})
    return if t.str == "pi"
        π
    elseif t.str == "/"
        /
    elseif t.str == "*"
        *
    elseif t.str == "+"
        +
    elseif t.str == "-"
        -
    else
        error("Unsupported reserved token: $t")
    end
end
function parsenode(t::OpenQASM.Types.Neg)
    return -parsenode(t.val)
end
function parsenode(t::Tuple)
    args = parsenode.(t)
    if length(args) == 3 && args[2] in [+, -, *, /]
        return args[2](args[1], args[3])
    else
        error("Unsupported token: $t")
    end
end

function parse_location(loc::OpenQASM.Types.Bit)
    if loc.address === nothing
        return AllLocs()
    else
        return convert(Int, loc.address) + 1  # In Julia, we start counting from 1
    end
end

### Noise model parsing
"""
    CustomKrausError <: AbstractErrorType

Custom Kraus error from a list of Kraus operators.

# Fields
- `kraus_ops::Vector{Matrix{ComplexF64}}`: The Kraus operators
"""
struct CustomKrausError <: AbstractErrorType
    kraus_ops::Vector{Matrix{ComplexF64}}
end
KrausChannel(error::CustomKrausError) = KrausChannel([matblock(op; tag="K$i") for (i, op) in enumerate(error.kraus_ops)])
quantum_channel(error::CustomKrausError) = KrausChannel(error)

"""
    ReadOutError

A readout error.

# Fields
- `locs::Vector{Vector{Int}}`: The locations of the readout error. To make it consistent with the noise model, the locations are nested vectors, each with one element, and is 1-based.
- `probability::Vector{Vector{Float64}}`: The probability of the readout error. The first element is the probability of 0, the second element is the probability of 1.
"""
struct ReadOutError
    locs::Vector{Vector{Int}}
    probability::Vector{Vector{Float64}}
end

"""
    parse_noise_model(data)

Parse a noise model from a dictionary.

# Arguments
- `data`: A vector of dictionaries, each containing noise type and parameters

# Returns
- `Tuple{Vector{ErrorPattern}, Vector{ReadOutError}}`: Gate errors and readout errors

# Supported noise types
- `"depolarizing"`: Single-qubit depolarizing noise
- `"depolarizing2"`: Two-qubit depolarizing noise
- `"thermal_relaxation"`: Thermal relaxation noise
- `"coherent_unitary"`: Coherent unitary error
- `"pauli"`: Pauli error with probability vector [X, Y, Z]
- `"amplitude_damping"`: Amplitude damping error
- `"phase_damping"`: Phase damping error
- `"phase_amplitude_damping"`: Combined phase and amplitude damping
- `"kraus"`: Kraus operators error
- `"roerror"`: Readout error
"""
function parse_noise_model(data)
    gate_errors = ErrorPattern[]
    ro_errors = ReadOutError[]
    _render_locs(locs) = [collect(Int, loc) .+ 1 for loc in locs]
    
    for noise in data
        noise_type = noise["type"]
        
        if noise_type == "depolarizing"
            # Single-qubit depolarizing noise
            err = DepolarizingError(1, noise["probability"])
            push!(gate_errors, ErrorPattern(_render_locs(noise["qubits"]), collect(String, noise["operations"]), err))

        elseif noise_type == "depolarizing2"
            # Two-qubit depolarizing noise
            err = DepolarizingError(2, noise["probability"])
            push!(gate_errors, ErrorPattern(_render_locs(noise["qubits"]), collect(String, noise["operations"]), err))

        elseif noise_type == "thermal_relaxation"
            # Thermal relaxation noise
            err = ThermalRelaxationError(noise["T1"], noise["T2"], noise["time"])
            push!(gate_errors, ErrorPattern(_render_locs(noise["qubits"]), collect(String, noise["operations"]), err))

        elseif noise_type == "coherent_unitary"
            # Coherent unitary error
            unitary_matrix = reduce(hcat, noise["unitary"])  # Convert to matrix
            unitary_block = matblock(unitary_matrix)
            err = CoherentError(unitary_block)
            push!(gate_errors, ErrorPattern(_render_locs(noise["qubits"]), collect(String, noise["operations"]), err))

        elseif noise_type == "pauli"
            # Pauli error with probability vector [X, Y, Z]
            probs = noise["probability"]  # [prob_X, prob_Y, prob_Z]
            err = PauliError(probs[1], probs[2], probs[3])
            push!(gate_errors, ErrorPattern(_render_locs(noise["qubits"]), collect(String, noise["operations"]), err))

        elseif noise_type == "amplitude_damping"
            # Amplitude damping error
            gamma = noise["gamma_amplitude"]
            excited_state_pop = noise["excited_state_population"]
            err = AmplitudeDampingError(gamma, excited_state_pop)
            push!(gate_errors, ErrorPattern(_render_locs(noise["qubits"]), collect(String, noise["operations"]), err))

        elseif noise_type == "phase_damping"
            # Phase damping error
            gamma = noise["gamma_phase"]
            err = PhaseDampingError(gamma)
            push!(gate_errors, ErrorPattern(_render_locs(noise["qubits"]), collect(String, noise["operations"]), err))

        elseif noise_type == "phase_amplitude_damping"
            # Combined phase and amplitude damping
            gamma_amp = noise["gamma_amplitude"]
            gamma_phase = noise["gamma_phase"]
            excited_state_pop = noise["excited_state_population"]
            err = PhaseAmplitudeDampingError(gamma_amp, gamma_phase, excited_state_pop)
            push!(gate_errors, ErrorPattern(_render_locs(noise["qubits"]), collect(String, noise["operations"]), err))

        elseif noise_type == "kraus"
            # Kraus operators error
            kraus_ops = [reduce(hcat, op) for op in noise["kraus_ops"]]  # Convert to matrices
            err = CustomKrausError(kraus_ops)
            push!(gate_errors, ErrorPattern(_render_locs(noise["qubits"]), collect(String, noise["operations"]), err))
            
        elseif noise_type == "roerror"
            # Readout error
            probability_matrix = noise["probability"]
            ro_error = ReadOutError(_render_locs(noise["qubits"]), probability_matrix)
            push!(ro_errors, ro_error)
        else
            error("unknown noise type: $(noise_type)")
        end
    end
    
    return gate_errors, ro_errors
end
