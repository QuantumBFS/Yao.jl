# Pauli Propagation Backend

Simulating noisy quantum circuits efficiently is a crucial challenge in quantum computing. The Pauli Propagation method[^Rudolph2025] provides an efficient way to simulate circuits under certain noise models by tracking how Pauli observables evolve through the circuit. The `PauliPropagation` extension in Yao provides a convenient interface to convert Yao circuits into the Pauli propagation framework.

## Overview

Pauli propagation represents quantum circuit simulation as the evolution of Pauli strings through gates and noise channels. This approach offers several advantages:

- **Efficiency**: Scales polynomially for certain circuit classes, especially with sparse Pauli evolution
- **Noise Support**: Natural representation of common noise models (depolarizing, Pauli channels)
- **Observable-Centric**: Directly computes expectation values without full state vector

The method works by propagating a Pauli observable backwards through the circuit, keeping track of how the observable transforms under gates and noise.

## Installation

The PauliPropagation extension is automatically loaded when you have both packages:

```julia
using Yao
using PauliPropagation
```

## Basic Usage

### Converting Circuits to PauliPropagation

The primary function for circuit conversion is:

```julia
yao2paulipropagation(circuit; observable)
```

This function transforms a Yao circuit into a `PauliPropagationCircuit` intermediate representation.

**Parameters:**

- `circuit::ChainBlock`: The quantum circuit to convert. Must contain only gates supported by PauliPropagation (Clifford gates, rotations, and noise channels)
- `observable`: A Yao block specifying the observable to measure. Must be a sum of Pauli strings

**Returns:**

- `PauliPropagationCircuit`: An intermediate representation containing the circuit gates and observable as a `PauliSum`

### Propagating Observables

Once you have a `PauliPropagationCircuit`, propagate the observable through the circuit:

```julia
propagate(pc; kwargs...)
```

**Returns:**

- `PauliSum`: The propagated observable. Use `overlapwithzero(psum)` to get the expectation value

## Example

Here's a complete example showing how to simulate a noisy quantum circuit:

```@example pauliprop
using Yao, PauliPropagation

# Create a noisy circuit with rotation gates and depolarizing noise
n = 5
circuit = chain(n,
    put(n, 1=>H),
    put(n, 2=>Rx(0.3)),
    control(n, 1, 2=>X),
    put(n, 1=>quantum_channel(DepolarizingError(1, 0.01)))
)

# Define an observable (e.g., measure Z on first qubit)
observable = put(n, 1=>Z)

# Convert to PauliPropagation representation
pc = yao2paulipropagation(circuit; observable=observable)

# Propagate the observable through the circuit
psum = propagate(pc)

# Get the expectation value
exp_pauli = real(overlapwithzero(psum))
println("PauliPropagation result: ", exp_pauli)

# Compare with exact density matrix simulation
reg = zero_state(n) |> density_matrix
reg_final = apply!(reg, circuit)
exp_exact = real(expect(observable, reg_final))
println("Exact simulation result: ", exp_exact)
println("Difference: ", abs(exp_pauli - exp_exact))
```

The observable can also be a sum of Pauli strings (e.g., a Hamiltonian):
```@example pauliprop
# Multi-term observable
hamiltonian = put(n, 1=>X) + 2.0 * kron(n, 1=>Z, 2=>Z)
pc2 = yao2paulipropagation(circuit; observable=hamiltonian)
exp_val = real(overlapwithzero(propagate(pc2)))
println("Hamiltonian expectation: ", exp_val)
```

## Supported Gates and Channels

### Clifford Gates
- Pauli gates: `X`, `Y`, `Z`
- Hadamard: `H`
- Phase gates: `S`, `T`, `Sdag`, `Tdag`
- Two-qubit gates: `control(n, ctrl, target=>X)` (CNOT), `control(n, ctrl, target=>Z)` (CZ), `SWAP`, `Toffoli`

### Rotation Gates
- `Rx(θ)`, `Ry(θ)`, `Rz(θ)` and their multi-qubit versions

### Noise Channels
- `DepolarizingChannel`: Depolarizing noise
- `MixedUnitaryChannel`: Pauli noise channels (X, Y, Z errors)
- `AmplitudeDampingError`: Amplitude damping

## API Reference

```@docs
yao2paulipropagation
paulipropagation2yao
```

### `PauliPropagationCircuit`

An intermediate representation that holds a circuit and observable in PauliPropagation format.

**Fields:**
- `n::Int`: Number of qubits
- `gates::Vector{StaticGate}`: Vector of frozen gates
- `observable::PauliSum`: Observable as a sum of Pauli strings

### `propagate(pc::PauliPropagationCircuit; kwargs...)`

Propagate the observable through the circuit.

**Keyword Arguments:**
- `max_weight`: Maximum Pauli weight to keep (default: no limit)
- `min_abs_coeff`: Minimum coefficient magnitude to keep (default: 0)

**Returns:** `PauliSum` - the propagated observable

## Performance Tips

1. **Truncation**: Use `max_weight` and `min_abs_coeff` to control the size of the Pauli sum during propagation
2. **Observable Choice**: Simpler observables (lower Pauli weight) propagate more efficiently
3. **Circuit Structure**: Circuits with limited entanglement spread maintain sparse Pauli sums
4. **Frozen Rotations**: All rotation parameters are frozen into the gates for efficient propagation

## References

[^Rudolph2025]: Rudolph, Manuel S., Jones, Tyson, Teng, Yanting, Angrisani, Armando, and Holmes, Zoe. "Pauli Propagation: A Computational Framework for Simulating Quantum Systems." arXiv:2505.21606 (2025). [https://arxiv.org/abs/2505.21606](https://arxiv.org/abs/2505.21606)

