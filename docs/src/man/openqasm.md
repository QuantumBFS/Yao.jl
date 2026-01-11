```@meta
CurrentModule = YaoBlocks
DocTestSetup = quote
    using Yao
    using Yao: YaoBlocks
end
```

# OpenQASM Support

Yao provides built-in support for [OpenQASM 2.0](https://openqasm.com/), a widely-used quantum assembly language. This allows you to:

- **Export** Yao circuits to OpenQASM format for use with other quantum computing frameworks
- **Import** OpenQASM circuits from other tools into Yao for simulation and analysis
- **Save** circuits to files for later use
- **Share** circuits across different quantum computing platforms

## Basic Usage

### Converting Circuits to QASM

Use the [`qasm`](@ref) function to convert a Yao circuit to an OpenQASM string:

```@repl openqasm
using Yao

# Simple single-qubit gate
qasm(put(2, 1=>X))

# Control gate (outputs QASM 2.0 compatible cx)
qasm(control(2, 1, 2=>X))

# A complete circuit
circuit = chain(2, put(1=>H), control(1, 2=>X))
qasm(circuit)
```

To include the full QASM header (version, includes, and register declarations), use `include_header=true`:

```@repl openqasm
qasm(circuit; include_header=true)
```

### Automatic Circuit Simplification

Before converting to QASM, circuits are automatically simplified using `Optimise.canonicalize`. This:
- Flattens nested chain blocks
- Converts complex gates to basic types
- Eliminates redundant structure

This means you can export complex circuits built with high-level constructs:

```@repl openqasm
using Yao.EasyBuild

# QFT circuit uses nested chains and controlled phase gates
circuit = qft_circuit(3)
println(qasm(circuit; include_header=true))
```

### Parsing QASM to Circuits

Use the [`parseblock`](@ref) function to convert an OpenQASM string to a Yao circuit:

```@repl openqasm
qasm_str = """
OPENQASM 2.0;
include "qelib1.inc";
qreg q[2];
creg c[2];
h q[0];
cx q[0],q[1];
measure q -> c;
""";

task = parseblock(qasm_str)
task.circuit
```

The returned `SimulationTask` contains:
- `task.circuit`: The quantum circuit as a `ChainBlock`
- `task.outcomes`: References to measurement outcomes

## Roundtrip Verification

Circuits can be converted to QASM and back with functional equivalence. This is verified by comparing fidelity:

```julia
using Yao, Yao.EasyBuild

# Create a circuit
circuit = variational_circuit(4, 2)

# Convert to QASM and back
qasm_str = qasm(circuit; include_header=true)
parsed = parseblock(qasm_str).circuit

# Verify equivalence
reg1 = rand_state(4)
reg2 = copy(reg1)
apply!(reg1, circuit)
apply!(reg2, parsed)
fidelity(reg1, reg2) ≈ 1.0  # true
```

This works for EasyBuild circuits including `qft_circuit`, `variational_circuit`, and `rand_google53`.

## Saving and Loading Circuits

### Save to File

```julia
using Yao

# Create a circuit
circuit = chain(3,
    put(1=>H),
    control(1, 2=>X),
    control(2, 3=>X),
    put(1=>Rz(0.5)),
    Measure(3)
)

# Convert to QASM and save
qasm_string = qasm(circuit; include_header=true)
write("my_circuit.qasm", qasm_string)
```

### Load from File

```julia
using Yao

# Read QASM file
qasm_string = read("my_circuit.qasm", String)

# Parse to Yao circuit
task = parseblock(qasm_string)
circuit = task.circuit

# Use the circuit
reg = zero_state(nqubits(circuit))
apply!(reg, circuit)
```

## Supported Gates

### Export (Yao → QASM)

**Single-Qubit Gates:**

| Yao Block | QASM Output |
|-----------|-------------|
| `I2` | `id` |
| `X`, `Y`, `Z` | `x`, `y`, `z` |
| `H` | `h` |
| `S`, `Sdag` | `s`, `inv @ s` |
| `T`, `Tdag` | `t`, `inv @ t` |
| `Rx(θ)`, `Ry(θ)`, `Rz(θ)` | `rx(θ)`, `ry(θ)`, `rz(θ)` |
| `shift(λ)` | `p(λ)` |

**Two-Qubit Gates:**

| Yao Block | QASM Output |
|-----------|-------------|
| `control(n, c, t=>X)` | `cx` |
| `control(n, c, t=>Y)` | `cy` |
| `control(n, c, t=>Z)` | `cz` |
| `control(n, c, t=>H)` | `ch` |
| `control(n, c, t=>shift(λ))` | `cu1(λ)` |
| `control(n, c, t=>Rz(θ))` | `crz(θ)` |
| `control(n, (c1,c2), t=>X)` | `ccx` (Toffoli) |
| `swap(n, i, j)` | `swap` |
| `rot(kron(Z,Z), θ)` | `rzz(θ)` |

**Modifiers:**

| Yao Block | QASM Output |
|-----------|-------------|
| `Daggered(G)` | `inv @ g` |
| `control(n, -c, t=>G)` | `negctrl @ g` (QASM 3.0) |

!!! note
    The compiler automatically uses QASM 2.0 gates when possible (e.g., `cx` instead of `ctrl @ x`) for maximum compatibility. QASM 3.0 modifiers (`ctrl @`, `negctrl @`, `inv @`) are used as fallback for complex cases.

### Import (QASM → Yao)

**Single-Qubit Gates:**

| QASM Gate | Yao Block |
|-----------|-----------|
| `id` | `I2` |
| `x`, `y`, `z` | `X`, `Y`, `Z` |
| `h` | `H` |
| `s`, `sdg` | `S`, `Sdag` |
| `t`, `tdg` | `T`, `Tdag` |
| `sx` | `matblock(SqrtX)` |
| `rx(θ)`, `ry(θ)`, `rz(θ)` | `Rx(θ)`, `Ry(θ)`, `Rz(θ)` |
| `u1(λ)`, `p(λ)` | `shift(λ)` |
| `u2(ϕ,λ)`, `u3(θ,ϕ,λ)` | `matblock(...)` |
| `r(θ,ϕ)` | `rot(cos(ϕ)X + sin(ϕ)Y, θ)` |

**Two-Qubit Gates:**

| QASM Gate | Yao Block |
|-----------|-----------|
| `cx`, `cy`, `cz` | `control(...=>X/Y/Z)` |
| `ch` | `control(...=>H)` |
| `crz(θ)` | `control(...=>Rz(θ))` |
| `cu1(λ)`, `cp(λ)` | `control(...=>shift(λ))` |
| `cu3(θ,ϕ,λ)` | `control(...=>matblock(...))` |
| `swap` | `swap(n, i, j)` |
| `rxx(θ)` | `rot(kron(X,X), θ)` |
| `rzz(θ)` | `rot(kron(Z,Z), θ)` |

**Three-Qubit Gates:**

| QASM Gate | Yao Block |
|-----------|-----------|
| `ccx` | `control((c1,c2), t=>X)` |

**Measurement:**

| QASM Gate | Yao Block |
|-----------|-----------|
| `measure q -> c` | `Measure(n)` |
| `measure q[i] -> c[j]` | `Measure(n; locs=...)` |

## Working with Other Frameworks

### Export to Qiskit

```julia
using Yao

# Create circuit in Yao
circuit = chain(2, put(1=>H), control(1, 2=>X))

# Save as QASM
write("bell_state.qasm", qasm(circuit; include_header=true))
```

Then in Python with Qiskit:
```python
from qiskit import QuantumCircuit
circuit = QuantumCircuit.from_qasm_file("bell_state.qasm")
```

### Import from Qiskit

Save your Qiskit circuit:
```python
from qiskit import QuantumCircuit
qc = QuantumCircuit(2)
qc.h(0)
qc.cx(0, 1)
qc.measure_all()
qc.qasm(filename="qiskit_circuit.qasm")
```

Load in Yao:
```julia
using Yao

qasm_str = read("qiskit_circuit.qasm", String)
task = parseblock(qasm_str)
circuit = task.circuit
```

### Export to Cirq, PennyLane, etc.

Since OpenQASM is a standard format, circuits exported from Yao can be loaded into any framework that supports QASM:

```julia
# Yao
write("circuit.qasm", qasm(circuit; include_header=true))
```

```python
# Cirq
import cirq
from cirq.contrib.qasm_import import circuit_from_qasm
circuit = circuit_from_qasm(open("circuit.qasm").read())

# PennyLane
import pennylane as qml
circuit = qml.from_qasm(open("circuit.qasm").read())
```

## Advanced: Noisy Simulation

For advanced users, Yao supports parsing circuits with noise models:

```julia
using Yao
using YaoBlocks: ErrorPattern, parse_noise_model

# Define noise model
noise_data = [
    Dict(
        "type" => "depolarizing",
        "operations" => ["x", "y", "z", "h"],
        "qubits" => [[0], [1]],
        "probability" => 0.01
    ),
    Dict(
        "type" => "depolarizing2",
        "operations" => ["cx"],
        "qubits" => [[0, 1]],
        "probability" => 0.02
    )
]

gate_errors, ro_errors = parse_noise_model(noise_data)

# Parse QASM with noise
qasm_str = """
OPENQASM 2.0;
include "qelib1.inc";
qreg q[2];
creg c[2];
h q[0];
cx q[0],q[1];
"""

task = parseblock(qasm_str, gate_errors)
# The circuit now includes noise channels after each gate
```

Supported noise types:
- `depolarizing` / `depolarizing2`: Single/two-qubit depolarizing noise
- `thermal_relaxation`: T1/T2 thermal relaxation
- `pauli`: Pauli X/Y/Z errors with individual probabilities
- `amplitude_damping`: Amplitude damping channel
- `phase_damping`: Phase damping channel
- `phase_amplitude_damping`: Combined amplitude and phase damping
- `coherent_unitary`: Coherent unitary error
- `kraus`: Custom Kraus operators
- `roerror`: Readout error

## Limitations

- Only `include "qelib1.inc"` is supported for include statements
- Custom gate definitions (`gate ... { }`) are not yet supported for parsing
- Only one `qreg` and one `creg` are supported per program
- Barriers are ignored (with a warning)
- Conditional operations (`if (c==n) gate`) are not supported

## API Reference

```@docs
qasm
parseblock
```
