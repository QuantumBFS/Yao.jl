# YaoToEinsum

[![CI](https://github.com/QuantumBFS/YaoToEinsum.jl/workflows/CI/badge.svg)](https://github.com/QuantumBFS/YaoToEinsum.jl/actions)

Convert Yao circuit to OMEinsum notation for tensor network based simulation.

## Installation

<p>
YaoToEinsum is a &nbsp;
    <a href="https://julialang.org">
        <img src="https://raw.githubusercontent.com/JuliaLang/julia-logo-graphics/master/images/julia.ico" width="16em">
        Julia Language
    </a>
    &nbsp; package. To install YaoToEinsum,
    please <a href="https://docs.julialang.org/en/v1/manual/getting-started/">open
    Julia's interactive session (known as REPL)</a> and press <kbd>]</kbd> key in the REPL to use the package mode, then type the following command
</p>

For stable release

```julia
pkg> add YaoToEinsum
```

For current master

```julia
pkg> add YaoToEinsum#master
```

If you have problem to install the package, please [file us an issue](https://github.com/QuantumBFS/YaoToEinsum.jl/issues/new).

## Example
This package contains one main function `yao2einsum(circuit; initial_state=Dict(), final_state=Dict())`.
It transform a [`Yao`](https://github.com/QuantumBFS/Yao.jl) circuit to a generalized tensor network (einsum) notation. 
This function returns a 2-tuple of (einsum code, input tensors). 
`initial_state` and `final_state` specifies the initial state and final state.
They can specified as a dictionary with integer keys, with value either integer or a single qubit register.
If a qubit of initial state or final state is not specified, the circuit will have open edges.

```julia
julia> import Yao, YaoToEinsum

julia> using Yao.EasyBuild: qft_circuit

julia> using YaoToEinsum: uniformsize, TreeSA, optimize_code

julia> n = 10;

julia> circuit = qft_circuit(n);

# convert circuit (open in both left and right) to einsum notation (code) and tensors.
julia> code, tensors = YaoToEinsum.yao2einsum(circuit);

# optimize contraction order, for more algorithms, please check `OMEinsumContractionOrders`.
julia> optcode = optimize_code(code, uniformsize(code, 2), TreeSA(ntrials=1));

julia> reshape(optcode(tensors...; size_info=uniformsize(code, 2)), 1<<n, 1<<n) ≈ Yao.mat(circuit)
true

# convert circuit (applied on product state `initial_state` and projected to output state `final_state`)
julia> code, tensors = YaoToEinsum.yao2einsum(circuit;
        initial_state=Dict([i=>0 for i=1:n]), final_state=Dict([i=>0 for i=1:n]));

julia> optcode = optimize_code(code, uniformsize(code, 2), TreeSA(ntrials=1));

julia> optcode(tensors...; size_info=uniformsize(code, 2))[] ≈ Yao.zero_state(n)' * (Yao.zero_state(n) |> circuit)
true
```

## References

* Simulating quantum computation by contracting tensor networks
https://arxiv.org/abs/quant-ph/0511069

* Simulating the Sycamore quantum supremacy circuits
https://arxiv.org/abs/2103.03074

* Solving the sampling problem of the Sycamore quantum supremacy circuits
https://arxiv.org/abs/2111.03011
