# error types
export AbstractErrorType, BitFlipError, PhaseFlipError, DepolarizingError, PauliError, ResetError,
    ThermalRelaxationError, PhaseAmplitudeDampingError, PhaseDampingError, AmplitudeDampingError,
    CoherentError

# channels
export KrausChannel, MixedUnitaryChannel, DepolarizingChannel, quantum_channel, SuperOp,
    add_noise, noisy_simulation

"""
    quantum_channel(error::AbstractErrorType)

Convert an error type to a quantum channel. The output type can be `KrausChannel`, `MixedUnitaryChannel`.
"""
function quantum_channel end

"""
    noisy_simulation(reg::ArrayReg, circuit::AbstractBlock)

Simulate a circuit with noise.

### Arguments
- `reg::ArrayReg`: the initial state of the system.
- `circuit::AbstractBlock`: the circuit to simulate.

### Returns
- `DensityMatrix`: the final state of the system.

### Examples
Add noise after each single-qubit gate and simulate the circuit.

```jldoctest; setup=:(using Yao)
julia> circ = Optimise.replace_block(chain(2, put(1=>X), control(2, 1=>X))) do block
           n = nqubits(block)
           if block isa PutBlock && length(block.locs) == 1
               return chain(block, put(n, block.locs => quantum_channel(BitFlipError(0.1))))  # add noise after each single-qubit gate
           elseif block isa ControlBlock && length(block.ctrl_locs) == 1 && length(block.locs) == 1
               return chain(block, put(n, (block.ctrl_locs..., block.locs...) => kron(quantum_channel(BitFlipError(0.1)), quantum_channel(BitFlipError(0.1)))))  # add noise after each control gate
           else
               return block
           end
       end
nqubits: 2
chain
├─ chain
│  ├─ put on (1)
│  │  └─ X
│  └─ put on (1)
│     └─ mixed_unitary_channel
│        ├─ [0.9] I2
│        └─ [0.1] X
└─ chain
   ├─ control(2)
   │  └─ (1,) X
   └─ put on (2, 1)
      └─ mixed_unitary_channel
         ├─ [0.81] kron
         │  ├─ 1=>I2
         │  └─ 2=>I2
         ├─ [0.09000000000000001] kron
         │  ├─ 1=>I2
         │  └─ 2=>X
         ├─ [0.09000000000000001] kron
         │  ├─ 1=>X
         │  └─ 2=>I2
         └─ [0.010000000000000002] kron
            ├─ 1=>X
            └─ 2=>X

julia> noisy_simulation(zero_state(2), circ)
DensityMatrix{2, ComplexF64, Array...}
    active qubits: 2/2
    nlevel: 2
```
"""
function noisy_simulation(reg::ArrayReg, circuit::AbstractBlock)
    return apply(density_matrix(reg), circuit)
end

include("superop.jl")
include("kraus.jl")
include("mixed_unitary_channel.jl")
include("errortypes.jl")
