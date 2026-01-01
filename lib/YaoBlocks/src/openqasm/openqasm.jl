"""
# OpenQASM Support

This module provides bidirectional conversion between YaoBlocks and OpenQASM 2.0/3.0.

## Exported Functions

- [`qasm`](@ref): Convert a YaoBlocks circuit to OpenQASM string
- [`parseblock`](@ref): Parse an OpenQASM string into a YaoBlocks circuit

## Basic Usage

### Converting Blocks to QASM

```julia
using Yao

# Simple gate
qasm(put(2, 1=>X))  # "x reg[0]"

# Control gate
qasm(control(2, 1, 2=>X))  # "ctrl @ x reg[0], reg[1]"

# Full circuit with header
circuit = chain(2, put(1=>H), control(1, 2=>X))
qasm(circuit; include_header=true)
```

### Parsing QASM to Blocks

```julia
using Yao

qasm_str = \"\"\"
OPENQASM 2.0;
include "qelib1.inc";
qreg q[2];
creg c[2];
h q[0];
cx q[0],q[1];
measure q -> c;
\"\"\"

task = parseblock(qasm_str)
circuit = task.circuit      # The quantum circuit
outcomes = task.outcomes    # Measurement outcome references
```

## Supported Gates

### Compilation (Block → QASM)
- Basic gates: I2, X, Y, Z, H, S, Sdag, T, Tdag
- Rotation gates: Rx, Ry, Rz
- Phase gate: shift (→ `p`)
- Control blocks with positive/negative controls
- Daggered blocks (→ `inv @`)
- Custom matrix blocks with tags

### Parsing (QASM → Block)
- Single-qubit: id, x, y, z, h, s, sdg, t, tdg, sx, r
- Rotations: rx, ry, rz
- U gates: u1/p, u2, u3
- Two-qubit: cx, cy, cz, ch, crz, cu1/cp, cu3, swap, rxx, rzz
- Three-qubit: ccx (Toffoli)
- Measurement: measure

## Noise Simulation (Advanced)

For noisy simulation, use the internal `parse_noise_model` function:

```julia
using Yao
using YaoBlocks: ErrorPattern, parse_noise_model

# Define noise patterns
noise_data = [Dict(
    "type" => "depolarizing",
    "operations" => ["x", "y", "z"],
    "qubits" => [[0]],
    "probability" => 0.01
)]
gate_errors, ro_errors = parse_noise_model(noise_data)

# Parse with noise
task = parseblock(qasm_str, gate_errors)
```

Supported noise types: `depolarizing`, `depolarizing2`, `thermal_relaxation`, 
`coherent_unitary`, `pauli`, `amplitude_damping`, `phase_damping`, 
`phase_amplitude_damping`, `kraus`, `roerror`.
"""

using OpenQASM
using OpenQASM.RBNF: Token

include("compile.jl")
include("parse.jl")
