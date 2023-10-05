# YaoToEinsum

[![CI](https://github.com/QuantumBFS/YaoToEinsum.jl/workflows/CI/badge.svg)](https://github.com/QuantumBFS/YaoToEinsum.jl/actions)
[![codecov](https://codecov.io/gh/QuantumBFS/YaoToEinsum.jl/graph/badge.svg?token=ZwzRcQCksQ)](https://codecov.io/gh/QuantumBFS/YaoToEinsum.jl)

Convert [Yao](https://github.com/QuantumBFS/Yao.jl) circuit to tensor networks (einsum).

## Installation

`YaoToEinsum` is a [Julia language](https://julialang.org/) package. To install `YaoToEinsum`, please [open Julia's interactive session (known as REPL)](https://docs.julialang.org/en/v1/manual/getting-started/) and press <kbd>]</kbd> key in the REPL to use the package mode, then type the following command

```julia
pkg> add YaoToEinsum
```

## Using
This package contains one main function `yao2einsum(circuit; initial_state=Dict(), final_state=Dict(), optimizer=TreeSA())`.
It transform a [`Yao`](https://github.com/QuantumBFS/Yao.jl) circuit to a generalized tensor network (einsum notation).  The return value is a `TensorNetwork` object.

* `initial_state` and `final_state` are for specifying the initial state and final state.
If any of them is not specified, the function will return a tensor network with open legs.
* `optimizer` is for optimizing the contraction order of the tensor network. The default value is `TreeSA()`. Please check the README of [OMEinsumContractors.jl](https://github.com/TensorBFS/OMEinsumContractionOrders.jl) for more information.

```julia
julia> import Yao, YaoToEinsum

julia> using Yao.EasyBuild: qft_circuit

julia> using YaoToEinsum: TreeSA

julia> n = 10;

julia> circuit = qft_circuit(n);

# convert this circuit to tensor network
julia> network = YaoToEinsum.yao2einsum(circuit)
TensorNetwork
Time complexity: 2^20.03816881914695
Space complexity: 2^20.0
Read-write complexity: 2^20.07564105083201

julia> reshape(contract(network), 1<<n, 1<<n) ≈ Yao.mat(circuit)
true

# convert circuit sandwiched by zero states
julia> network = YaoToEinsum.yao2einsum(circuit;
        initial_state=Dict([i=>0 for i=1:n]), final_state=Dict([i=>0 for i=1:n]),
        optimizer=TreeSA(; nslices=3)) # slicing technique
TensorNetwork
Time complexity: 2^12.224001674198101
Space complexity: 2^5.0
Read-write complexity: 2^13.036173612553485

julia> contract(network)[] ≈ Yao.zero_state(n)' * (Yao.zero_state(n) |> circuit)
true
```

## Contribute and Cite
If you have any questions or suggestions, please feel free to open an issue or pull request.
If you use this package in your work, please cite the relevant part of the papers included in [CITATION.bib](CITATION.bib).