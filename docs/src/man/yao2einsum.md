# Tensor Network Backend

Simulating quantum circuits using tensor networks is a powerful approach that has been extensively studied in quantum computing literature[^Markov2008][^Pan2022]. The `YaoToEinsum` package provides a convenient and efficient way to convert Yao circuits into tensor networks, enabling advanced analysis, optimization, and simulation of quantum circuits.

## Overview

Tensor networks represent quantum circuits as collections of interconnected tensors, where quantum gates become tensors and quantum states are represented as tensor contractions. This representation offers several advantages:

- **Scalability**: Efficient simulation of certain quantum circuits
- **Flexibility**: Easy manipulation and analysis of quantum operations
- **Optimization**: Advanced contraction order optimization for better performance

## Basic Usage

### Converting Circuits to Tensor Networks

The primary function for circuit conversion is:

```julia
using Yao, LuxorGraphPlot

yao2einsum(circuit; initial_state=Dict(), final_state=Dict(), optimizer=TreeSA())
```

This function transforms a [`Yao`](https://github.com/QuantumBFS/Yao.jl) circuit into a tensor network represented in Einstein summation (einsum) notation, returning a `TensorNetwork` object.

**Parameters:**

- `initial_state`: Dictionary specifying the initial quantum state. Unspecified qubits remain as open indices
- `final_state`: Dictionary specifying the final measurement state. Unspecified qubits remain as open indices  
- `optimizer`: Contraction order optimization algorithm. Default is `TreeSA()` developed in [^Kalachev2021][^Liu2023]. For more optimization algorithms, see [OMEinsumContractionOrders.jl](https://github.com/TensorBFS/OMEinsumContractionOrders.jl)

## Tutorial: Quantum Fourier Transform Example

In this tutorial, we demonstrate how to convert a Quantum Fourier Transform (QFT) circuit to a tensor network and use it for several common tasks:

1. Obtaining the matrix representation of the circuit
2. Computing probability amplitudes of specific states
3. Computing expectation values of observables
4. Simulating noisy circuits with density matrices

### Step 1: Create the Circuit

First, let's create a 10-qubit Quantum Fourier Transform circuit:

```@example yao2einsum
using Yao, LuxorGraphPlot
using Yao.EasyBuild: qft_circuit

n = 4
circuit = qft_circuit(n)  # Create a QFT circuit for n qubits
```

### Case 1: Matrix Representation

Now we convert the circuit to a tensor network representation:

```@example yao2einsum
network = Yao.yao2einsum(circuit)  # Convert circuit to tensor network
viznet(network)  # Visualize the network structure
```

This creates a tensor network where each quantum gate becomes a tensor node, and the connections represent shared indices between tensors.

We can contract the tensor network to obtain the full matrix representation of the circuit:

```@example yao2einsum
# Contract the network and reshape to get the unitary matrix
matrix_from_network = reshape(Yao.contract(network), 1<<n, 1<<n)
matrix_from_yao = Yao.mat(circuit)

# Verify they are equivalent
matrix_from_network ≈ matrix_from_yao
```

### Case 2: Computing Probability Amplitudes

For many applications, we're interested in specific probability amplitudes rather than the full matrix. Here we compute the probability amplitude for measuring all qubits in the |0⟩ state after applying the QFT to the |0⟩ state:

```@example yao2einsum
# Create a network with fixed initial and final states
network_with_states = Yao.yao2einsum(circuit;
    initial_state=Dict([i=>0 for i=1:n]),  # Start in |00...0⟩
    final_state=Dict([i=>0 for i=1:n]),    # Measure in |00...0⟩ basis
    optimizer=Yao.YaoToEinsum.TreeSA()
)
viznet(network_with_states)
```

```@example yao2einsum
# Contract the network to get the amplitude
amplitude_from_network = Yao.contract(network_with_states)[]

# Compare with direct Yao computation
initial_state = Yao.zero_state(n)
final_state = initial_state |> circuit
amplitude_from_yao = (Yao.zero_state(n)' * final_state)[]

amplitude_from_network ≈ amplitude_from_yao
```

### Case 3: Computing Observable Expectation Values

Tensor networks are particularly useful for computing expectation values of observables. Here we compute the expectation value of a Pauli-Z operator on the first qubit after applying the QFT:

```@example yao2einsum
# Define the observable (Pauli-Y on first qubit)
observable = put(n, 1=>Y)

# Create tensor network for expectation value computation
# We need to use the `DensityMatrixMode` to sandwich the circuit between the initial state and the observable
network_obs = Yao.yao2einsum(circuit;
    initial_state=Dict(1=>0, 2=>1, 3=>1, 4=>1),  # Start in |0111⟩
    observable = observable,     # Measure expectation value
    mode = DensityMatrixMode()
)
viznet(network_obs)
```

Contract to get the expectation value
```@example yao2einsum
res_network = real(Yao.contract(network_obs)[])
```

Compare with direct Yao computation

```@example yao2einsum
state_after_circuit = product_state(bit"1110") |> circuit
res_exact = real(expect(observable, state_after_circuit))
```

### Case 4: Noisy Circuit Simulation

YaoToEinsum supports simulation of noisy quantum circuits using different representations. We demonstrate both density matrix and Pauli basis modes for simulating decoherence:

```@example yao2einsum
# Create a simpler circuit for noisy simulation
n_small = 3
γ = 0.1  # damping parameter

# Create amplitude damping channels
damping_channel = quantum_channel(AmplitudeDampingError(γ))

# Build noisy circuit: gate followed by noise on the same qubits
noisy_circuit = chain(n_small,
    put(1=>X), put(1=>damping_channel),
    put(2=>H), put(2=>damping_channel), 
    cnot(1,2), put(1=>damping_channel), put(2=>damping_channel),
    put(3=>Z), put(3=>damping_channel)
)
```

#### Density Matrix Mode

Simulate using density matrix representation
```@example yao2einsum
network_dm = Yao.yao2einsum(noisy_circuit; 
    mode=DensityMatrixMode(),
    initial_state=Dict([i=>0 for i=1:n_small]),
    observable=put(n_small, 1=>Z)
)
viznet(network_dm)
```

Contract to get the final density matrix
```@example yao2einsum
res_network = contract(network_dm)[]
```

Compare with direct Yao simulation
```@example yao2einsum
initial_dm = density_matrix(zero_state(n_small))
res_exact = expect(put(n_small, 1=>Z), apply(initial_dm, noisy_circuit))
```

#### Pauli Basis Mode

Simulate using Pauli basis representation
```@example yao2einsum
network_pauli = Yao.yao2einsum(noisy_circuit;
    mode=PauliBasisMode(),
    initial_state=Dict([i=>0 for i=1:n_small]),
    observable=put(n_small, 1=>Z)
)
viznet(network_pauli)
```

Contract to get Pauli coefficients and verify the result
```@example yao2einsum
res_pauli = Yao.contract(network_pauli)
```

## API Reference

The following functions and types are exported by `YaoToEinsum`:

```@docs
yao2einsum
TensorNetwork
optimize_code
contraction_complexity
contract
```

## References

[^Markov2008]: Markov, Igor L., and Yaoyun Shi. "Simulating quantum computation by contracting tensor networks." SIAM Journal on Computing 38.3 (2008): 963-981.

[^Pan2022]: Pan, Feng, and Pan Zhang. "Simulation of quantum circuits using the big-batch tensor network method." Physical Review Letters 128.3 (2022): 030501.

[^Kalachev2021]: Kalachev, Gleb, Pavel Panteleev, and Man-Hong Yung. "Recursive multi-tensor contraction for xeb verification of quantum circuits." arXiv preprint arXiv:2108.05665 (2021).

[^Liu2023]: Liu, Jin-Guo, et al. "Computing solution space properties of combinatorial optimization problems via generic tensor networks." SIAM Journal on Scientific Computing 45.3 (2023): A1239-A1270.
