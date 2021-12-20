export AbstractRegister, AdjointRegister, DensityMatrix

"""
    AbstractRegister{B}

Abstract type for quantum registers. `B` is the batch size.
"""
abstract type AbstractRegister{B} end

"""
    AdjointRegister{B, T, RT} <: AbstractRegister{B, T}

Lazy adjoint for a quantum register.
"""
struct AdjointRegister{B,RT<:AbstractRegister{B}} <: AbstractRegister{B}
    parent::RT
end

"""
    instruct!(state, operator[, locs, control_locs, control_configs, theta])

instruction implementation for applying an operator to a quantum state.

This operator will be overloaded for different operator or state with
different types.
"""
@interface instruct!

# properties
"""
    nactive(register) -> Int

Returns the number of active qubits.

!!! note

    Operators always apply on active qubits.
"""
@interface nactive

"""
    nqubits(register) -> Int

Returns the (total) number of qubits. See [`nactive`](@ref), [`nremain`](@ref)
for more details.
"""
@interface nqubits

"""
    nremain(register) -> Int

Returns the number of non-active qubits.
"""
@interface nremain

"""
    nbatch(register) -> Int

Returns the number of batches.
"""
@interface nbatch

"""
    viewbatch(register, i::Int) -> AbstractRegister{1}

Returns a view of the i-th slice on batch dimension.
"""
@interface viewbatch

###################### Reg Operations: Location and size #####################
"""
    addbits!(register, n::Int) -> register
    addbits!(n::Int) -> λ(register)

Add `n` qubits to given register in state |0>.
i.e. |psi> -> |000> ⊗ |psi>, increased bits have higher indices.

If only an integer is provided, then returns a lambda function.
"""
@interface addbits!

"""
    insert_qubits!(register, loc::Int; nqubits::Int=1) -> register
    insert_qubits!(loc::Int; nqubits::Int=1) -> λ(register)

Insert `n` qubits to given register in state |0>.
i.e. |psi> -> |psi> ⊗ |000> ⊗ |psi>, increased bits have higher indices.

If only an integer is provided, then returns a lambda function.
"""
@interface insert_qubits!

"""
    focus!(register, locs) -> register

Focus the wires on specified location.

# Example

```julia
julia> focus!(r, (1, 2, 4))

```
"""
@interface focus!

"""
    relax!(register[, locs]; to_nactive=nqubits(register)) -> register

Inverse transformation of [`focus!`](@ref), where `to_nactive` is the number
 of active bits for target register.
"""
@interface relax!

"""
    partial_tr(register, locs)

Return a register which is the partial traced on `locs`.
"""
@interface partial_tr

"""
    reorder!(reigster, orders)

Reorder the locations of register by input orders.
"""
@interface reorder!

"""
    invorder(register)

Inverse the locations of register.
"""
@interface invorder!

"""
    collapseto!(register, config)

Set the `register` to bit string literal `bit_str` (or an equivalent integer). About bit string literal,
see more in [`@bit_str`](@ref).
"""
@interface collapseto!

##################### Measure ###################
export ComputationalBasis, AllLocs
export ResetTo, RemoveMeasured, NoPostProcess, PostProcess

struct ComputationalBasis end
struct AllLocs end

abstract type PostProcess end
struct ResetTo{T} <: PostProcess
    x::T
end
struct RemoveMeasured <: PostProcess end
struct NoPostProcess <: PostProcess end

"""
    measure([, operator], register[, locs]; nshots=1, rng=Random.GLOBAL_RNG) -> Vector{Int}

Return measurement results of qubits in `locs`.
If `locs` is not provided, all current active qubits are measured (regarding to active qubits,
see [`focus!`](@ref) and [`relax!`](@ref)).
"""
@interface measure

"""
    measure!([postprocess,] [operator, ]register[, locs]; rng=Random.GLOBAL_RNG)

Measure current active qubits or qubits at `locs`. After measure and collapse,

    * do nothing if postprocess is `NoPostProcess`
    * reset to result state to `postprocess.config` if `postprocess` is `ResetTo`.
    * remove the qubit if `postprocess` is `RemoveMeasured`
"""
@interface measure!

"""
    select!(dest::AbstractRegister, src::AbstractRegister, bits::Integer...) -> AbstractRegister
    select!(register::AbstractRegister, bits::Integer...) -> register

select a subspace of given quantum state based on input eigen state `bits`.
See also [`select`](@ref).

## Example

`select!(reg, 0b110)` will select the subspace with (focused) configuration `110`.
After selection, the focused qubit space is 0, so you may want call `relax!` manually.

!!! tip

    Developers should overload `select!(r::RegisterType, bits::NTuple{N, <:Integer})` and
    do not assume `bits` has specific number of bits (e.g `Int64`), or it will restrict the
    its maximum available number of qubits.
"""
@interface select!

"""
    select(register, bits) -> AbstractRegister

Non-inplace version of [`select!`](@ref).
"""
@interface select

###################### Other Operations #################
"""
    probs(register)

Returns the probability distribution of computation basis, aka ``|<x|ψ>|^2``.
"""
@interface probs

"""
    fidelity(register1, register2)

Return the fidelity between two states.

# Definition
The fidelity of two quantum state for qubits is defined as:

```math
F(ρ, σ) = tr(\\sqrt{\\sqrt{ρ}σ\\sqrt{ρ}})
```

Or its equivalent form (which we use in numerical calculation):

```math
F(ρ, σ) = sqrt(tr(ρσ) + 2 \\sqrt{det(ρ)det(σ)})
```

# Reference

- Jozsa R. Fidelity for mixed quantum states[J]. Journal of modern optics, 1994, 41(12): 2315-2323.
- Nielsen M A, Chuang I. Quantum computation and quantum information[J]. 2002.

!!! note

    The original definition of fidelity ``F`` was from "transition probability",
    defined by Jozsa in 1994, it is the square of what we use here.
"""
@interface fidelity

"""
    tracedist(register1, register2)

Return the trace distance of `register1` and `register2`.

# Definition
Trace distance is defined as following:

```math
\\frac{1}{2} || A - B ||_{tr}
```

# Reference

- https://en.wikipedia.org/wiki/Trace_distance
"""
@interface tracedist

#################### Error Handling ######################
export NotImplementedError, LocationConflictError, QubitMismatchError

# NOTE: kwargs do not involve in multiple dispatch
#       no need to store kwargs
struct NotImplementedError{ArgsT} <: Exception
    name::Symbol
    args::ArgsT
end

struct LocationConflictError <: Exception
    msg::String
end

# NOTE: More detailed error msg?
"""
    QubitMismatchError <: Exception

Qubit number mismatch error when applying a Block to a Register or concatenating Blocks.
"""
struct QubitMismatchError <: Exception
    msg::String
end

####################### Operator properties ###############
"""
    isunitary(op) -> Bool

check if this operator is a unitary operator.
"""
@interface isunitary

"""
    isreflexive(op) -> Bool

check if this operator is reflexive.
"""
@interface isreflexive

"""
    iscommute(ops...) -> Bool

check if operators are commute.
"""
@interface iscommute

####################### Density Matrix ############

"""
    DensityMatrix{B, T, MT}

Density Matrix.

- `B`: batch size
- `T`: element type
"""
struct DensityMatrix{B,T,MT<:AbstractArray{T,3}} <: AbstractRegister{B}
    state::MT
end

"""
    purify(r::DensityMatrix{B}; nbit_env::Int=nactive(r)) -> ArrayReg

Get a purification of target density matrix.
"""
@interface purify

"""
    density_matrix(register)

Returns the density matrix of current active qubits.
"""
@interface density_matrix

"""
    ρ(register)

Returns the density matrix of current active qubits. This is the same as
[`density_matrix`](@ref).
"""
@interface ρ
