export AbstractRegister, AdjointRegister, DensityMatrix

"""
    AbstractRegister{D}

Abstract type for quantum registers.
Type parameter `D` is the number of levels in each qudit.
For qubits, `D = 2`.
"""
abstract type AbstractRegister{D} end


"""
    AdjointRegister{D, RT<:AbstractRegister{D}} <: AbstractRegister{D}

Lazy adjoint for a quantum register, `RT` is the parent register type.
"""
struct AdjointRegister{D,RT<:AbstractRegister{D}} <: AbstractRegister{D}
    parent::RT
end


"""
    instruct!([nlevel=Val(2), ]state, operator, locs[, control_locs, control_configs, theta])

Unified interface for applying an operator to a quantum state.
It modifies the `state` directly.

Positional arguments
-----------------------------
    * `nlevel` is the number of levels in each qudit,
    * `state` is a matrix representing the quantum state, where the first dimension is the active qubit dimension, the second is the batch dimension.
    * `operator` is a quantum operator, which can be `Val(GATE_SYMBOL)` or a matrix.
    * `locs` is a tuple for specifying the locations this gate applied.
    * `control_locs` and `control_configs` are tuples for specifying the control locations and control values.
    * `theta` is the parameter for the gate, e.g. `Val(:Rx)` gate takes a real number of its parameter.
"""
@interface instruct!

# properties
"""
    nactive(register) -> Int

Returns the number of active qudits in `register`.
Here, active qudits means the system qubits that operators can be applied on.
"""
@interface nactive

"""
    nqubits(register) -> Int

Returns the (total) number of qubits. See [`nactive`](@ref), [`nremain`](@ref)
for more details.
"""
@interface nqubits

"""
    nqudits(register) -> Int

Returns the total number of qudits in `register`.
"""
@interface nqudits

"""
    nremain(register) -> Int

Returns the number of inactive qudits in `register`.
It equals to subtracting [`nqudits`](@ref) and [`nactive`](@ref).
"""
@interface nremain

"""
    viewbatch(register, i::Int) -> AbstractRegister

Returns the `i`-th single register of a batched register.
The returned instance is a view of the original register, i.e. inplace operation changes the original register directly.

Example
-------------------------------
```jldoctest; setup=:(using Yao)
julia> reg = zero_state(5; nbatch=2)
BatchedArrayReg{2, ComplexF64, Transpose...}
    active qubits: 5/5
    nlevel: 2
    nbatch: 2

julia> apply!(viewbatch(reg, 2), put(5, 2=>X))
ArrayReg{2, ComplexF64, SubArray...}
    active qubits: 5/5
    nlevel: 2

julia> measure(reg; nshots=3)
3×2 Matrix{BitBasis.BitStr64{5}}:
 00000 ₍₂₎  00010 ₍₂₎
 00000 ₍₂₎  00010 ₍₂₎
 00000 ₍₂₎  00010 ₍₂₎
```
"""
@interface viewbatch

###################### Reg Operations: Location and size #####################
"""
    append_qudits!(register, n::Int) -> register
    append_qudits!(n::Int) -> λ(register)

Add `n` qudits to given register in state |0>.
i.e. |psi> -> |000> ⊗ |psi>, increased bits have higher indices.

If only an integer is provided, then returns a lambda function.

Example
-------------------------------
```jldoctest; setup=:(using Yao)
julia> reg = product_state(bit"01101")
ArrayReg{2, ComplexF64, Array...}
    active qubits: 5/5
    nlevel: 2

julia> append_qudits!(reg, 2)
ArrayReg{2, ComplexF64, Array...}
    active qubits: 7/7
    nlevel: 2

julia> measure(reg; nshots=3)
3-element Vector{BitBasis.BitStr64{7}}:
 0001101 ₍₂₎
 0001101 ₍₂₎
 0001101 ₍₂₎
```
Note here, we read the bit string from right to left.
"""
@interface append_qudits!

"""
    append_qubits!(register, n::Int) -> register
    append_qubits!(n::Int) -> λ(register)

Add `n` qudits to given register in state |0>.
It is an alias of [`append_qudits!`](@ref) function.
"""
@interface append_qubits!

"""
    insert_qudits!(register, loc::Int, nqudits::Int) -> register
    insert_qudits!(loc::Int, nqudits::Int) -> λ(register)

Insert qudits to given register in state |0>.
i.e. |psi> -> join(|psi>, |0...>, |psi>), increased bits have higher indices.


Example
-------------------------------
```jldoctest; setup=:(using Yao)
julia> reg = product_state(bit"01101")
ArrayReg{2, ComplexF64, Array...}
    active qubits: 5/5
    nlevel: 2

julia> insert_qudits!(reg, 2, 2)
ArrayReg{2, ComplexF64, Array...}
    active qubits: 7/7
    nlevel: 2

julia> measure(reg; nshots=3)
3-element Vector{BitBasis.BitStr64{7}}:
 0110001 ₍₂₎
 0110001 ₍₂₎
 0110001 ₍₂₎
```
"""
@interface insert_qudits!

"""
    insert_qubits!(register, loc::Int, nqubits::Int=1) -> register
    insert_qubits!(loc::Int, nqubits::Int=1) -> λ(register)

Insert `n` qubits to given register in state |0>.
It is an alias of [`insert_qudits!`](@ref) function.
"""
@interface insert_qubits!

"""
    focus!(register, locs) -> register

Focus the wires on specified location.

Example
-------------------------------
```jldoctest; setup=:(using Yao)
julia> reg = product_state(bit"01101")
ArrayReg{2, ComplexF64, Array...}
    active qubits: 5/5
    nlevel: 2

julia> focus!(reg, (1,3,4))
ArrayReg{2, ComplexF64, Array...}
    active qubits: 3/5
    nlevel: 2

julia> measure(reg; nshots=3)
3-element Vector{BitBasis.BitStr64{3}}:
 111 ₍₂₎
 111 ₍₂₎
 111 ₍₂₎

julia> measure(apply(reg, put(3, 2=>X)); nshots=3)
3-element Vector{BitBasis.BitStr64{3}}:
 101 ₍₂₎
 101 ₍₂₎
 101 ₍₂₎
```

Here, we prepare a product state and only look at the qubits 1, 3 and 4. The measurement results are all ones.
With the focued register, we can apply a block of size 3 on it, even though the number of qubits is 5.
"""
@interface focus!

"""
    focus(f, register, locs)

Call a callable `f` under the context of `focus`. See also [`focus!`](@ref).

Example
-------------------------------
To print the focused register

```jldoctest; setup=:(using Yao)
julia> r = ArrayReg(bit"101100")
ArrayReg{2, ComplexF64, Array...}
    active qubits: 6/6
    nlevel: 2

julia> focus(x->(println(x);x), r, (1, 2));
ArrayReg{2, ComplexF64, Array...}
    active qubits: 2/6
    nlevel: 2
```
"""
@interface focus

function focus(f, r::AbstractRegister, locs::NTuple{N, Int}) where N
    focus!(r, locs)
    ret = f(r)
    relax!(r, locs)
    return ret
end

focus(f, r::AbstractRegister, locs::Int...) = focus(f, r, locs)


"""
    relax!(register[, locs]; to_nactive=nqudits(register)) -> register

Inverse transformation of [`focus!`](@ref), where `to_nactive` is the number
 of active bits for target register.

Example
-------------------------------
```jldoctest; setup=:(using Yao)
julia> reg = product_state(bit"01101")
ArrayReg{2, ComplexF64, Array...}
    active qubits: 5/5
    nlevel: 2

julia> focus!(reg, (1,3,4))
ArrayReg{2, ComplexF64, Array...}
    active qubits: 3/5
    nlevel: 2

julia> relax!(reg, (1,3,4))
ArrayReg{2, ComplexF64, Array...}
    active qubits: 5/5
    nlevel: 2
```
"""
@interface relax!

"""
    partial_tr(register, locs) -> 

Return a register which is the partial traced on `locs`.
"""
@interface partial_tr

"""
    reorder!(reigster, orders)

Reorder the locations of register by input orders.

Example
-------------------------------
```jldoctest; setup=:(using Yao)
```
"""
@interface reorder!

"""
    invorder(register)

Inverse the locations of register.

Example
-------------------------------
```jldoctest; setup=:(using Yao)
```
"""
@interface invorder!

"""
    collapseto!(register, config)

Set the `register` to bit string literal `bit_str` (or an equivalent integer). About bit string literal,
see more in [`@bit_str`](@ref).

Example
-------------------------------
```jldoctest; setup=:(using Yao)
```
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

Return measurement results of qudits in `locs`.
If `locs` is not provided, all current active qudits are measured (regarding to active qudits,
see [`focus!`](@ref) and [`relax!`](@ref)).

Example
-------------------------------
```jldoctest; setup=:(using Yao)
```
"""
@interface measure

"""
    measure!([postprocess,] [operator, ]register[, locs]; rng=Random.GLOBAL_RNG)

Measure current active qudits or qudits at `locs`. After measure and collapse,

    * do nothing if postprocess is `NoPostProcess`
    * reset to result state to `postprocess.config` if `postprocess` is `ResetTo`.
    * remove the qubit if `postprocess` is `RemoveMeasured`

Example
-------------------------------
```jldoctest; setup=:(using Yao)
```
"""
@interface measure!

"""
    select!(dest::AbstractRegister, src::AbstractRegister, bits::Integer...) -> AbstractRegister
    select!(register::AbstractRegister, bits::Integer...) -> register

select a subspace of given quantum state based on input eigen state `bits`.
See also [`select`](@ref).

Example
-------------------------------
```jldoctest; setup=:(using Yao)
```

`select!(reg, 0b110)` will select the subspace with (focused) configuration `110`.
After selection, the focused qubit space is 0, so you may want call `relax!` manually.

!!! tip

    Developers should overload `select!(r::RegisterType, bits::NTuple{N, <:Integer})` and
    do not assume `bits` has specific number of bits (e.g `Int64`), or it will restrict the
    its maximum available number of qudits.
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

Example
-------------------------------
```jldoctest; setup=:(using Yao)
```
"""
@interface probs

"""
    fidelity(register1, register2)

Return the fidelity between two states.

# Definition
The fidelity of two quantum state for qudits is defined as:

```math
F(ρ, σ) = tr(\\sqrt{\\sqrt{ρ}σ\\sqrt{ρ}})
```

Or its equivalent form (which we use in numerical calculation):

```math
F(ρ, σ) = sqrt(tr(ρσ) + 2 \\sqrt{det(ρ)det(σ)})
```

Example
-------------------------------
```jldoctest; setup=:(using Yao)
```

Reference
-------------------------------

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

Example
-------------------------------
```jldoctest; setup=:(using Yao)
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
    DensityMatrix{D, T, MT}

Density Matrix.

- `T`: element type
"""
struct DensityMatrix{D,T,MT<:AbstractMatrix{T}} <: AbstractRegister{D}
    state::MT
end

"""
    purify(r::DensityMatrix; nbit_env::Int=nactive(r)) -> ArrayReg

Get a purification of target density matrix.

Example
-------------------------------
```jldoctest; setup=:(using Yao)
```
"""
@interface purify

"""
    density_matrix(register)

Returns the density matrix of current active qudits.
"""
@interface density_matrix

"""
    ρ(register)

Returns the density matrix of current active qudits. This is the same as
[`density_matrix`](@ref).
"""
@interface ρ
