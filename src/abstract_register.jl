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

increase!(n::Int) = r -> increase!(r, n)

"""
    focus!(register, locs::Int...) -> register
    focus!(locs::Int...) -> f(register) -> register

Focus the wires on specified location.
"""
@interface focus!(::AbstractRegister, locs...)

"""
    relax!(register[, locs]) -> register
    relax!(nbits, locs) -> f(register) -> register

Inverse transformation of [`focus!`](@ref), where `nbit` is the number
 of active bits for target register.
"""
@interface relax!(::AbstractRegister, locs)

## Measurement

"""
    measure(register[, ntimes=1]) -> Vector{Int}

Return measurement results of current active qubits (regarding to active qubits,
see [`focus!`](@ref) and [`relax!`](@ref)).
"""
@interface measure(::AbstractRegister, ntimes::Int=1)

"""
    measure!(register[, locs])

measure and collapse to result state.
"""
@interface measure!(::AbstractRegister)

"""
    measure_remove!(::AbstractRegister[, locs])

measure the active qubits of this register and remove them.
"""
@interface measure_remove!(::AbstractRegister)

"""
    measure_reset!(reg::AbstractRegister[, locs]; [val=0]) -> Int

measure and set the register to specific value.
"""
@interface measure_reset!(::AbstractRegister; val::Int=0)


for FUNC in [:measure_reset!, :measure!, :measure]
    @eval function $FUNC(reg::AbstractRegister, locs; args...)
        focus!(reg, locs)
        res = $FUNC(reg; args...)
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

Base.length(::BatchIterator{B}) where B = B

# fallback printing
function Base.show(io::IO, reg::AbstractRegister)
    summary(io, reg)
    print(io, "\n    active qubits: ", nactive(reg), "/", nqubits(reg))
end
