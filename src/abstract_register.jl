using BitBasis

export AbstractRegister

"""
    AbstractRegister{B, T}

Abstract type for quantum registers. `B` is the batch size, `T` is the
data type.
"""
abstract type AbstractRegister{B, T} end

# properties
"""
    nactive(register) -> Int

Returns the number of active qubits.

!!! note

    Operators always apply on active qubits.
"""
@interface nactive(::AbstractRegister)

"""
    nqubits(register) -> Int

Returns the (total) number of qubits. See [`nactive`](@ref), [`nremain`](@ref)
for more details.
"""
@interface nqubits(::AbstractRegister)

"""
    nremain(register) -> Int

Returns the number of non-active qubits.
"""
@interface nremain(r::AbstractRegister) = nqubits(r) - nactive(r)

"""
    nbatch(register) -> Int

Returns the number of batches.
"""
@interface nbatch(r::AbstractRegister{B}) where B = B

# same with nbatch
Base.length(r::AbstractRegister{B}) where B = B

"""
    datatype(register) -> Int

Returns the numerical data type used by register.

!!! note

    `datatype` is not the same with `eltype`, since `AbstractRegister` family
    is not exactly the same with `AbstractArray`, it is an iterator of several
    registers.
"""
@interface datatype(r::AbstractRegister{B, T}) where {B, T} = T

"""
    increase!(register, n::Int) -> register
    increase!(n::Int) -> λ(register)

Increase the register by n bits in state |0>.
i.e. |psi> -> |000> ⊗ |psi>, increased bits have higher indices.

If only an integer is provided, then returns a lambda function.
"""
@interface increase!(::AbstractRegister, n::Int)

increase!(n::Int) = @λ(register -> increase!(register, n))

"""
    focus!(register, locs) -> register

Focus the wires on specified location.

# Example

```julia
julia> focus!(r, (1, 2, 4))

```
"""
@interface focus!(r::AbstractRegister, locs)

"""
    focus!(locs...) -> f(register) -> register

Lazy version of [`focus!`](@ref), this returns a lambda which requires a register.
"""
focus!(locs::Int...) = focus!(locs)
focus!(locs::NTuple{N, Int}) where N = @λ(register -> focus!(register, locs))

"""
    focus(f, register, locs...)

Call a callable `f` under the context of `focus`. See also [`focus!`](@ref).

# Example

print the focused register

```julia
julia> r = ArrayReg(bit"101100")
ArrayReg{1,Complex{Float64},Array...}
    active qubits: 6/6

julia> focus(x->(println(x);x), r, 1, 2);
ArrayReg{1,Complex{Float64},Array...}
    active qubits: 2/6
```
"""
@interface focus(f::Base.Callable, r::AbstractRegister, locs::Int...) = focus(f, r, locs)

focus(f::Base.Callable, r::AbstractRegister, loc::Int) = focus(f, r, (loc, ))
focus(f::Base.Callable, r::AbstractRegister, locs) =
    relax!(f(focus!(r, locs)), locs; to_nactive=nqubits(r))

"""
    relax!(register[, locs]; to_nactive=nqubits(register)) -> register

Inverse transformation of [`focus!`](@ref), where `to_nactive` is the number
 of active bits for target register.
"""
@interface relax!(r::AbstractRegister, locs; to_nactive::Int=nqubits(r))
relax!(r::AbstractRegister; to_nactive::Int=nqubits(r)) = relax!(r, (); to_nactive=to_nactive)

"""
    relax!(locs::Int...; to_nactive=nqubits(register)) -> f(register) -> register

Lazy version of [`relax!`](@ref), it will be evaluated once you feed a register
to its output lambda.
"""
relax!(locs::Int...; to_nactive::Union{Nothing, Int}=nothing) =
    relax!(locs; to_nactive=to_nactive)

function relax!(locs::NTuple{N, Int}; to_nactive::Union{Nothing, Int}=nothing) where N
    lambda = function (r::AbstractRegister)
        if to_nactive === nothing
            return relax!(r, locs...; to_nactive=nqubits(r))
        else
            return relax!(r, locs...; to_nactive=to_nactive)
        end
    end
    return LegibleLambda(
        "(register->relax!(register, locs...; to_nactive))",
        lambda)
end

## Measurement

"""
    measure(register[, locs]; ntimes=1) -> Vector{Int}

Return measurement results of current active qubits (regarding to active qubits,
see [`focus!`](@ref) and [`relax!`](@ref)).
"""
@interface measure(::AbstractRegister; ntimes::Int=1)

"""
    measure!(register[, locs])

Measure current active qubits or qubits at `locs` and collapse to result state.
"""
@interface measure!(::AbstractRegister)

"""
    measure_remove!(::AbstractRegister[, locs])

Measure current active qubits or qubits at `locs` and remove them.
"""
@interface measure_remove!(::AbstractRegister)

"""
    measure_reset!(reg::AbstractRegister[, locs]; bit_config) -> Int

Measure current active qubits or qubits at `locs` and set the register to specific value.
"""
@interface measure_setto!(::AbstractRegister; bit_config::Int=0)

# focus context
for FUNC in [:measure_reset!, :measure!, :measure, :measure_setto!]
    @eval function $FUNC(reg::AbstractRegister, locs; kwargs...)
        focus!(reg, locs)
        res = $FUNC(reg; kwargs...)
        relax!(reg, locs)
        return res
    end
end

"""
    select!(dest::AbstractRegister, src::AbstractRegister, bits::Integer...) -> AbstractRegister
    select!(register::AbstractRegister, bits::Integer...) -> register
    select!(b::Integer) -> f(register)

select a subspace of given quantum state based on input eigen state `bits`.

## Example

`select!(reg, 0b110)` will select the subspace with (focused) configuration `110`.
After selection, the focused qubit space is 0, so you may want call `relax!` manually.
"""
@interface select!(::AbstractRegister, bits...)

"""
    select(register, bits...) -> AbstractRegister

Non-inplace version of [`select!`](@ref).
"""
@interface select(register::AbstractRegister, bits...) = select!(copy(register), bits...)

"""
    cat(::AbstractRegister...) -> register

Merge several registers as one register via tensor product.
"""
@interface Base.cat(::AbstractRegister...)

"""
    repeat(r::AbstractRegister, n::Int) -> register

Repeat register `r` for `n` times on batch dimension.

### Example
"""
@interface Base.repeat(::AbstractRegister, n::Int)

"""
    basis(register) -> UnitRange

Returns an `UnitRange` of the all the bits in the Hilbert space of given register.
"""
@interface BitBasis.basis(r::AbstractRegister) = basis(nqubits(r))

"""
    probs(register)

Returns the probability distribution of computation basis, aka ``|<x|ψ>|^2``.
"""
@interface probs(r::AbstractRegister)

"""
    reorder!(reigster, orders)

Reorder the address of register by input orders.
"""
@interface reorder!(r::AbstractRegister, orders)

"""
    invorder(register)

Inverse the address of register.
"""
@interface invorder!(r::AbstractRegister) = reorder!(r, Tuple(nactive(reg):-1:1))

"""
    setto!(register, bit_str)

Set the `register` to bit string literal `bit_str`. About bit string literal,
see more in [`@bit_str`](@ref).
"""
@interface setto!(r::AbstractRegister, bit_str::BitStr) = setto!(r, bit_str.val)

"""
    setto!(register, bit_config::Integer)

Set the `register` to bit configuration `bit_config`.
"""
@interface setto!(r::AbstractRegister, bit_config::Integer=0)

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
@interface fidelity(r1::AbstractRegister, r2::AbstractRegister)

"""
    trace_distance(register1, register2)

Return the trace distance of `register1` and `register2`.

# Definition
Trace distance is defined as following:

```math
\\frac{1}{2} || A - B ||_{tr}
```

# Reference

- https://en.wikipedia.org/wiki/Trace_distance
"""
@interface trace_distance(r1::AbstractRegister, r2::AbstractRegister)

"""
    density_matrix(register)

Returns the density matrix of current active qubits.
"""
@interface density_matrix(::AbstractRegister)

"""
    ρ(register)

Returns the density matrix of current active qubits. This is the same as
[`density_matrix`](@ref).
"""
@interface ρ(x) = density_matrix(x)

"""
    viewbatch(register, i::Int) -> AbstractRegister{1}

Returns a view of the i-th slice on batch dimension.
"""
@interface viewbatch(::AbstractRegister, ::Int)


function Base.iterate(it::AbstractRegister{B}, state=1) where B
    if state > B
        return nothing
    else
        return viewbatch(it, state), state + 1
    end
end

# fallback printing
function Base.show(io::IO, reg::AbstractRegister)
    summary(io, reg)
    print(io, "\n    active qubits: ", nactive(reg), "/", nqubits(reg))
end
