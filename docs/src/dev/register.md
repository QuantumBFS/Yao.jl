# Quantum Register

Quantum Register is the abstraction of a quantum state being processed
by a quantum circuit.

## The Interface of Register

You can always define your own quantum register by subtyping this abstract type.

```@docs
AbstractRegister
```

The interface of a `AbstractRegister` looks like:

### Properties

- `nqubit`: number of qubits
- `nbatch`: number of batch
- `nactive`: number of active qubits
- `address`: current list of line address
- `state`: current state
- `eltype`: eltype
- `copy`: copy
- `focus!`: pack several legs together

### Factory Methods

```@docs
Register
```

- `reshaped_state`: state
