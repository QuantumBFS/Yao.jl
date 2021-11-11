# YaoToEinsum

[![CI](https://github.com/QuantumBFS/YaoToEinsum.jl/workflows/CI/badge.svg)](https://github.com/QuantumBFS/YaoToEinsum.jl/actions)

Convert Yao circuit to OMEinsum notation for tensor network based simulation.

## Example
```julia
julia> import Yao, YaoToEinsum

help?> YaoToEinsum.yao2einsum
  yao2einsum(circuit; initial_state=nothing, final_state=nothing)

  Transform a Yao circuit to a generalized tensor network (einsum) notation. 
  This function returns a 2-tuple of (einsum code, input tensors). 
  initial_state and final_state specifies the initial state and final state
  as product states, e.g. a vector [1, 1, 0, 1] specifies a product state |1⟩⊗|1⟩⊗|0⟩⊗|1⟩. 
  If initial state or final state is not specified, the circuit will have open edges.

julia> using YaoExtensions: qft_circuit

julia> using OMEinsumContractionOrders: optimize_code, TreeSA, uniformsize

julia> n = 10;

julia> circuit = qft_circuit(n);

# convert circuit (open in both left and right) to einsum notation (code) and tensors.
julia> code, tensors = YaoToEinsum.yao2einsum(circuit);

# optimize code, for more methods, check `OMEinsumContractionOrders`.
julia> optcode = optimize_code(code, uniformsize(code, 2), TreeSA(ntrials=1));

julia> reshape(optcode(tensors...; size_info=uniformsize(code, 2)), 1<<n, 1<<n) ≈ Yao.mat(circuit)
true

# convert circuit (applied on product state `initial_state` and projected to output state `final_state`)
julia> code, tensors = YaoToEinsum.yao2einsum(circuit; initial_state=zeros(Bool, n), final_state=zeros(Bool, n));

julia> optcode = optimize_code(code, uniformsize(code, 2), TreeSA(ntrials=1));

julia> optcode(tensors...; size_info=uniformsize(code, 2))[] ≈ Yao.zero_state(n)' * (Yao.zero_state(n) |> circuit)
true
```
