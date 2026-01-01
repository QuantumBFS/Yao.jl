```@meta
CurrentModule = YaoBlocks
DocTestSetup = quote
    using Yao
    using Yao: YaoBlocks
end
```

# OpenQASM Support

Yao provides built-in support for [OpenQASM](https://openqasm.com/), a widely-used quantum assembly language. This allows you to:

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

# Control gate
qasm(control(2, 1, 2=>X))

# A complete circuit
circuit = chain(2, put(1=>H), control(1, 2=>X))
qasm(circuit)
```

To include the full QASM header (version, includes, and register declarations), use `include_header=true`:

```@repl openqasm
qasm(circuit; include_header=true)
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

| Yao Block | QASM Output |
|-----------|-------------|
| `I2` | `id` |
| `X`, `Y`, `Z` | `x`, `y`, `z` |
| `H` | `h` |
| `S`, `Sdag` | `s`, `inv @ s` |
| `T`, `Tdag` | `t`, `inv @ t` |
| `Rx(θ)`, `Ry(θ)`, `Rz(θ)` | `rx(θ)`, `ry(θ)`, `rz(θ)` |
| `shift(λ)` | `p(λ)` |
| `control(n, c, t=>G)` | `ctrl @ g` |
| `control(n, -c, t=>G)` | `negctrl @ g` |
| `Daggered(G)` | `inv @ g` |

### Import (QASM → Yao)

| QASM Gate | Yao Block |
|-----------|-----------|
| `id` | `I2` |
| `x`, `y`, `z` | `X`, `Y`, `Z` |
| `h` | `H` |
| `s`, `sdg` | `S`, `Sdag` |
| `t`, `tdg` | `T`, `Tdag` |
| `rx(θ)`, `ry(θ)`, `rz(θ)` | `Rx(θ)`, `Ry(θ)`, `Rz(θ)` |
| `u1(λ)`, `p(λ)` | `shift(λ)` |
| `u2(ϕ,λ)`, `u3(θ,ϕ,λ)` | `matblock(...)` |
| `cx`, `cy`, `cz` | `control(...=>X/Y/Z)` |
| `ccx` | `control((c1,c2), t=>X)` |
| `swap` | `swap(n, i, j)` |
| `rxx(θ)`, `rzz(θ)` | `rot(kron(X,X), θ)`, etc. |
| `measure q -> c` | `Measure(n)` |

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

## API Reference

```@docs
qasm
parseblock
```
