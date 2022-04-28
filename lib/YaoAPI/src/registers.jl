export AbstractRegister, AdjointRegister, DensityMatrix

"""
    AbstractRegister{D}

Abstract type for quantum registers.
Type parameter `D` is the number of levels in each qudit.
For qubits, `D = 2`.


### Required methods

* [`instruct!`](@ref)

* [`nqudits`](@ref)
* [`nactive`](@ref)

* [`insert_qubits!`](@ref)
* [`append_qubits!`](@ref)

* [`focus!`](@ref)
* [`relax!`](@ref)
* [`reorder!`](@ref)
* [`invorder!`](@ref)

### Optional methods
* [`nlevel`](@ref)
* [`nremain`](@ref)
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

### Arguments

* `nlevel` is the number of levels in each qudit,
* `state` is a vector or matrix representing the quantum state, where the first dimension is the active qubit dimension, the second is the batch dimension.
* `operator` is a quantum operator, which can be `Val(GATE_SYMBOL)` or a matrix.
* `locs::Tuple` is a tuple for specifying the locations this gate applied.
* `control_locs::Tuple` and `control_configs` are tuples for specifying the control locations and control values.
* `theta::Real` is the parameter for the gate, e.g. `Val(:Rx)` gate takes a real number of its parameter.
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

### Examples

```jldoctest; setup=:(using Yao)
julia> reg = zero_state(5; nbatch=2);

julia> apply!(viewbatch(reg, 2), put(5, 2=>X));

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

### Examples

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


### Examples

```jldoctest; setup=:(using Yao)
julia> reg = product_state(bit"01101")
ArrayReg{2, ComplexF64, Array...}
    active qubits: 5/5
    nlevel: 2

julia> insert_qudits!(reg, 2, 2)
ArrayReg{2, ComplexF64, Array...}
    active qubits: 7/11
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

### Examples

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

### Examples

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

### Examples

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
    partial_tr(ρ, locs) -> 

Return a density matrix which is the partial traced on `locs`.
"""
@interface partial_tr

"""
    reorder!(reigster, orders)

Reorder the locations of register by input orders.
For a 3-qubit register, an order `(i, j, k)` specifies the following reordering of qubits
* move the first qubit go to `i`,
* move the second qubit go to `j`,
* move the third qubit go to `k`.

!!! note

    The convention of `reorder!` is different from the `permutedims` function, one can use the `sortperm` function to relate the permutation order and the order in this function.

### Examples
```jldoctest; setup=:(using Yao)
julia> reg = product_state(bit"010101");

julia> reorder!(reg, (1,4,2,5,3,6));

julia> measure(reg)
1-element Vector{BitBasis.BitStr64{6}}:
 000111 ₍₂₎
```
"""
@interface reorder!

"""
    invorder!(register)

Inverse the locations of the register.

### Examples

```jldoctest; setup=:(using Yao)
julia> reg = product_state(bit"010101")
ArrayReg{2, ComplexF64, Array...}
    active qubits: 6/6
    nlevel: 2

julia> measure(invorder!(reg); nshots=3)
3-element Vector{BitBasis.BitStr64{6}}:
 101010 ₍₂₎
 101010 ₍₂₎
 101010 ₍₂₎
```
"""
@interface invorder!

"""
    collapseto!(register, config)

Set the `register` to bit string literal `bit_str` (or an equivalent integer). About bit string literal,
see more in [`@bit_str`](@ref).
This interface is only for emulation.

### Examples

The following code collapse a random state to a certain state.

```jldoctest; setup=:(using Yao)
julia> measure(collapseto!(rand_state(3), bit"001"); nshots=3)
3-element Vector{BitBasis.BitStr64{3}}:
 001 ₍₂₎
 001 ₍₂₎
 001 ₍₂₎
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

Measure a quantum state and return measurement results of qudits.
This measurement function a cheating version of `measure!` that does not collapse the input state.
It also does not need to recompute the quantum state for performing multiple shots measurement.

### Arguments
* `operator::AbstractBlock` is the operator to measure.
* `register::AbstractRegister` is the quantum state.
* `locs` is the qubits to performance the measurement. If `locs` is not provided, all current active qudits are measured (regarding to active qudits,
see [`focus!`](@ref) and [`relax!`](@ref)).

### Keyword arguments
* `nshots::Int` is the number of shots.
* `rng` is the random number generator.

### Examples

```jldoctest; setup=:(using Yao)
julia> reg = product_state(bit"110")
ArrayReg{2, ComplexF64, Array...}
    active qubits: 3/3
    nlevel: 2

julia> measure(reg; nshots=3)
3-element Vector{BitBasis.BitStr64{3}}:
 110 ₍₂₎
 110 ₍₂₎
 110 ₍₂₎

julia> measure(reg, (2,3); nshots=3)
3-element Vector{BitBasis.BitStr64{2}}:
 11 ₍₂₎
 11 ₍₂₎
 11 ₍₂₎
```
 
The following example switches to the X basis for measurement.

```jldoctest; setup=:(using Yao)
julia> reg = product_state(bit"110")
ArrayReg{2, ComplexF64, Array...}
    active qubits: 3/3
    nlevel: 2
```
"""
@interface measure

"""
    measure!([postprocess,] [operator, ]register[, locs]; rng=Random.GLOBAL_RNG)

Measure current active qudits or qudits at `locs`.
If the operator is not provided, it will measure on the computational basis and collapse to a product state.
Otherwise, the quantum state collapse to the subspace corresponds to the resulting eigenvalue of the observable.

### Arguments

* `postprocess` is the postprocessing method, it can be
    * `NoPostProcess()` (default).
    * `ResetTo(config)`, reset to result state to `config`. It can not be used if `operator` is provided, because measuring an operator in general does not return a product state.
    * `RemoveMeasured()`, remove the measured qudits from the register. It is also incompatible with the `operator` argument.
* `operator::AbstractBlock` is the operator to measure.
* `register::AbstractRegister` is the quantum state.
* `locs` is the qubits to performance the measurement. If `locs` is not provided, all current active qudits are measured (regarding to active qudits,
see [`focus!`](@ref) and [`relax!`](@ref)).

### Keyword arguments
* `rng` is the random number generator.

### Examples

The following example measures a random state on the computational basis and reset it to a certain bitstring value.
```jldoctest; setup=:(using Yao, Random; Random.seed!(2))
julia> reg = rand_state(3);

julia> measure!(ResetTo(bit"011"), reg)
110 ₍₂₎

julia> measure(reg; nshots=3)
3-element Vector{BitBasis.BitStr64{3}}:
 011 ₍₂₎
 011 ₍₂₎
 011 ₍₂₎

julia> measure!(RemoveMeasured(), reg, (1,2))
11 ₍₂₎

julia> reg  # removed qubits are not usable anymore
ArrayReg{2, ComplexF64, Array...}
    active qubits: 1/1
    nlevel: 2
```
"""
@interface measure!

"""
    select!(dest::AbstractRegister, src::AbstractRegister, bits::Integer...) -> AbstractRegister
    select!(register::AbstractRegister, bits::Integer...) -> register

select a subspace of given quantum state based on input eigen state `bits`.
See also [`select`](@ref) for the non-inplace version.

### Examples

```jldoctest; setup=:(using Yao)
julia> reg = ghz_state(3)
ArrayReg{2, ComplexF64, Array...}
    active qubits: 3/3
    nlevel: 2

julia> select!(reg, bit"111")
ArrayReg{2, ComplexF64, Array...}
    active qubits: 0/0
    nlevel: 2

julia> norm(reg)
0.7071067811865476
```

The selection only works on the activated qubits, for example
```
julia> reg = focus!(ghz_state(3), (1, 2))
ArrayReg{2, ComplexF64, Array...}
    active qubits: 2/3
    nlevel: 2

julia> select!(reg, bit"11")
ArrayReg{2, ComplexF64, Array...}
    active qubits: 0/1
    nlevel: 2

julia> statevec(reg)
1×2 Matrix{ComplexF64}:
 0.0+0.0im  0.707107+0.0im
```

!!! tip

    Developers should overload `select!(r::RegisterType, bits::NTuple{N, <:Integer})` and
    do not assume `bits` has specific number of bits (e.g `Int64`), or it will restrict the
    its maximum available number of qudits.
"""
@interface select!

"""
    select(register, bits) -> AbstractRegister

The non-inplace version of [`select!`](@ref).
"""
@interface select

###################### Other Operations #################
"""
    probs(register) -> Vector

Returns the probability distribution of computation basis, aka ``|<x|ψ>|^2``.

### Examples

```jldoctest; setup=:(using Yao)
julia> reg = product_state(bit"101");

julia> reg |> probs
8-element Vector{Float64}:
 0.0
 0.0
 0.0
 0.0
 0.0
 1.0
 0.0
 0.0
```
"""
@interface probs

"""
    fidelity(register1, register2) -> Real/Vector{<:Real}
    fidelity'(pair_or_reg1, pair_or_reg2) -> (g1, g2)

Return the fidelity between two states.
Calcuate the fidelity between `r1` and `r2`, if `r1` or `r2` is not pure state
(`nactive(r) != nqudits(r)`), the fidelity is calcuated by purification. See also
[`pure_state_fidelity`](@ref), [`purification_fidelity`](@ref).

Obtain the gradient with respect to registers and circuit parameters.
For pair input `ψ=>circuit`, the returned gradient is a pair of `gψ=>gparams`,
with `gψ` the gradient of input state and `gparams` the gradients of circuit parameters.
For register input, the return value is a register.


# Definition
The fidelity of two quantum state for qudits is defined as:

```math
F(ρ, σ) = tr(\\sqrt{\\sqrt{ρ}σ\\sqrt{ρ}})
```

Or its equivalent form (which we use in numerical calculation):

```math
F(ρ, σ) = sqrt(tr(ρσ) + 2 \\sqrt{det(ρ)det(σ)})
```

### Examples

```jldoctest; setup=:(using Yao)
julia> reg1 = uniform_state(3);

julia> reg2 = zero_state(3);

julia> fidelity(reg1, reg2)
0.35355339059327373
```

### References

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
\\frac{1}{2} || A - B ||_{\\rm tr}
```

### Examples

```jldoctest; setup=:(using Yao)
julia> reg1 = uniform_state(3);

julia> reg2 = zero_state(3);

julia> tracedist(reg1, reg2)
1.8708286933869704
```

### References

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

####################### Density Matrix ############

"""
    DensityMatrix{D,T,MT<:AbstractMatrix{T}} <: AbstractRegister{D}
    DensityMatrix{D}(state::AbstractMatrix)
    DensityMatrix(state::AbstractMatrix; nlevel=2)

Density matrix type, where `state` is a matrix.
Type parameter `D` is the number of levels, it can also be specified by a keyword argument `nlevel`.
"""
struct DensityMatrix{D,T,MT<:AbstractMatrix{T}} <: AbstractRegister{D}
    state::MT
end

"""
    purify(r::DensityMatrix; nbit_env::Int=nactive(r)) -> ArrayReg

Get a purification of target density matrix.

### Examples

The following example shows how to measure a local operator on the register, reduced density matrix and the purified register.
Their results should be consistent.

```jldoctest; setup=:(using Yao)
julia> reg = ghz_state(3)
ArrayReg{2, ComplexF64, Array...}
    active qubits: 3/3
    nlevel: 2

julia> r = density_matrix(reg, (2,));

julia> preg = purify(r)
ArrayReg{2, ComplexF64, Array...}
    active qubits: 1/2
    nlevel: 2

julia> expect(Z + Y, preg)
4.266421588589642e-17 + 0.0im

julia> expect(Z + Y, r)
0.0 + 0.0im

julia> expect(put(3, 2=>(Z + Y)), reg)
0.0 + 0.0im
```
"""
@interface purify

"""
    density_matrix(register, locations)

Returns the density matrix for qubits on `locations`.

### Examples

The following code gets the single site reduce density matrix for the GHZ state.

```jldoctest; setup=:(using Yao)
julia> reg = ghz_state(3)
ArrayReg{2, ComplexF64, Array...}
    active qubits: 3/3
    nlevel: 2

julia> density_matrix(reg, (2,)).state
2×2 Matrix{ComplexF64}:
 0.5+0.0im  0.0+0.0im
 0.0-0.0im  0.5+0.0im
```
"""
@interface density_matrix

"""
    clone(register, n)

Create an [`ArrayReg`](@ref) by cloning the original `register` for `n` times on batch dimension.
This function is only for emulation.

# Example

```jldoctest; setup=:(using YaoArrayRegister)
julia> clone(arrayreg(bit"101"; nbatch=3), 4)
BatchedArrayReg{2, ComplexF64, Array...}
    active qubits: 3/3
    nlevel: 2
    nbatch: 12
```
"""
@interface clone