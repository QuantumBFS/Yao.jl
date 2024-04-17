# Tensor network backend

Simulating quantum circuits using tensor networks has been studied in the literature[^Markov2008][^Pan2022]. The `YaoToEinsum` package provides a convenient way to convert Yao circuits to tensor networks, which can be used for further analysis and optimization.

## Tutorial
The main function is
```julia
yao2einsum(circuit; initial_state=Dict(), final_state=Dict(), optimizer=TreeSA())
```
which transforms a [`Yao`](https://github.com/QuantumBFS/Yao.jl) circuit to a tensor network that generalizes the hyper-graph (einsum notation).  The return value is a `TensorNetwork` object.

* `initial_state` and `final_state` are for specifying the initial state and final state. Left the qubits unspecified if you want to keep them as the open indices.
* `optimizer` is for specifying the contraction order optimizing algorithm of the tensor network. The default value is the `TreeSA()` algorithm that developed in [^Kalachev2021][^Liu2023]. Please check the README of [OMEinsumEinsumContractors.jl](https://github.com/TensorBFS/OMEinsumContractionOrders.jl) for more information.

In the following example, we show how to convert a quantum Fourier transform circuit to a tensor network and contract it to
- Get the matrix representation of the circuit.
- Get the probability of measuring the zero state after applying the circuit on the zero state.

```@repl
import Yao
using Yao.EasyBuild: qft_circuit
n = 10;
circuit = qft_circuit(n);  # build a quantum Fourier transform circuit
network = Yao.yao2einsum(circuit)  # convert this circuit to tensor network
reshape(Yao.contract(network), 1<<n, 1<<n) ≈ Yao.mat(circuit)
network = Yao.yao2einsum(circuit;  # convert circuit sandwiched by zero states
        initial_state=Dict([i=>0 for i=1:n]), final_state=Dict([i=>0 for i=1:n]),
        optimizer=Yao.YaoToEinsum.TreeSA(; nslices=3)) # slicing technique
Yao.contract(network)[] ≈ Yao.zero_state(n)' * (Yao.zero_state(n) |> circuit)
```

## API
```@docs
yao2einsum
TensorNetwork
optimize_code
contraction_complexity
contract
```

## References
[^Pan2022]: Pan, Feng, and Pan Zhang. "Simulation of quantum circuits using the big-batch tensor network method." Physical Review Letters 128.3 (2022): 030501.
[^Kalachev2021]: Kalachev, Gleb, Pavel Panteleev, and Man-Hong Yung. "Recursive multi-tensor contraction for xeb verification of quantum circuits." arXiv preprint arXiv:2108.05665 (2021).
[^Markov2008]: Markov, Igor L., and Yaoyun Shi. "Simulating quantum computation by contracting tensor networks." SIAM Journal on Computing 38.3 (2008): 963-981.
[^Liu2023]: Liu, Jin-Guo, et al. "Computing solution space properties of combinatorial optimization problems via generic tensor networks." SIAM Journal on Scientific Computing 45.3 (2023): A1239-A1270.