using BitBasis, LegibleLambdas

export AbstractRegister, @λ, @lambda

"""
    AbstractRegister{B}

Abstract type for quantum registers. `B` is the batch size.
"""
abstract type AbstractRegister{B} end

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
@interface nbatch(r::AbstractRegister{B}) where {B} = B

# same with nbatch
Base.length(r::AbstractRegister{B}) where {B} = B

"""
    addbits!(register, n::Int) -> register
    addbits!(n::Int) -> λ(register)

Add `n` qubits to given register in state |0>.
i.e. |psi> -> |000> ⊗ |psi>, increased bits have higher indices.

If only an integer is provided, then returns a lambda function.
"""
@interface addbits!(::AbstractRegister, n::Int)

addbits!(n::Int) = @λ(register -> addbits!(register, n))

"""
    insert_qubits!(register, loc::Int; nqubits::Int=1) -> register
    insert_qubits!(loc::Int; nqubits::Int=1) -> λ(register)

Insert `n` qubits to given register in state |0>.
i.e. |psi> -> |psi> ⊗ |000> ⊗ |psi>, increased bits have higher indices.

If only an integer is provided, then returns a lambda function.
"""
@interface insert_qubits!(::AbstractRegister, loc::Int; nqubits::Int = 1)
insert_qubits!(loc::Int; nqubits::Int = 1) =
    @λ(register -> insert_qubits!(register, loc; nqubits = n))


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
focus!(locs::NTuple{N,Int}) where {N} = @λ(register -> focus!(register, locs))
focus!(locs::UnitRange) = @λ(register -> focus!(register, locs))
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
@interface focus!(f::Base.Callable, r::AbstractRegister, locs::Int...) = focus(f, r, locs)

focus!(f::Base.Callable, r::AbstractRegister, loc::Int) = focus(f, r, (loc,))
focus!(f::Base.Callable, r::AbstractRegister, locs) =
    relax!(f(focus!(r, locs)), locs; to_nactive = nqubits(r))

"""
    relax!(register[, locs]; to_nactive=nqubits(register)) -> register

Inverse transformation of [`focus!`](@ref), where `to_nactive` is the number
 of active bits for target register.
"""
@interface relax!(r::AbstractRegister, locs; to_nactive::Int = nqubits(r))
relax!(r::AbstractRegister; to_nactive::Int = nqubits(r)) = relax!(r, (); to_nactive = to_nactive)

"""
    relax!(locs::Int...; to_nactive=nqubits(register)) -> f(register) -> register

Lazy version of [`relax!`](@ref), it will be evaluated once you feed a register
to its output lambda.
"""
relax!(locs::Int...; to_nactive::Union{Nothing,Int} = nothing) = relax!(locs; to_nactive = to_nactive)

function relax!(locs::NTuple{N,Int}; to_nactive::Union{Nothing,Int} = nothing) where {N}
    lambda = function (r::AbstractRegister)
        if to_nactive === nothing
            return relax!(r, locs; to_nactive = nqubits(r))
        else
            return relax!(r, locs; to_nactive = to_nactive)
        end
    end

    @static if VERSION < v"1.1.0"
        return LegibleLambda("(register->relax!(register, locs...; to_nactive))", lambda)
    else
        return LegibleLambda(
            lambda,
            :(register -> relax!(register, locs...; to_nactive)),
            Dict(:locs => locs, :to_nactive => to_nactive),
        )
    end
end

## Measurement

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

export measure, measure!

"""
    measure(register[, operator][, locs]; nshots=1, rng=Random.GLOBAL_RNG) -> Vector{Int}

Return measurement results of qubits in `locs`.
If `locs` is not provided, all current active qubits are measured (regarding to active qubits,
see [`focus!`](@ref) and [`relax!`](@ref)).
"""
function measure end

"""
    measure!([postprocess,] [operator, ]register[, locs]; rng=Random.GLOBAL_RNG)

Measure current active qubits or qubits at `locs`. After measure and collapse,

    * do nothing if postprocess is `NoPostProcess`
    * reset to result state to `postprocess.config` if `postprocess` is `ResetTo`.
    * remove the qubit if `postprocess` is `RemoveMeasured`
"""
function measure! end

measure!(postprocess::PostProcess, op, reg::AbstractRegister; kwargs...) =
    measure!(postprocess, op, reg, AllLocs(); kwargs...)
measure!(postprocess::PostProcess, reg::AbstractRegister, locs; kwargs...) =
    measure!(postprocess, ComputationalBasis(), reg, locs; kwargs...)
measure!(postprocess::PostProcess, reg::AbstractRegister; kwargs...) =
    measure!(postprocess, ComputationalBasis(), reg, AllLocs(); kwargs...)
measure!(op, reg::AbstractRegister, args...; kwargs...) =
    measure!(NoPostProcess(), op, reg, args...; kwargs...)
measure!(reg::AbstractRegister, args...; kwargs...) =
    measure!(NoPostProcess(), reg, args...; kwargs...)

measure(op, reg::AbstractRegister; kwargs...) = measure(op, reg, AllLocs(); kwargs...)
measure(reg::AbstractRegister, locs; kwargs...) = measure(ComputationalBasis(), reg, locs; kwargs...)
measure(reg::AbstractRegister; kwargs...) = measure(ComputationalBasis(), reg, AllLocs(); kwargs...)

# focus! to specify locations, we that we only need to consider full-space measure in the future.
function measure!(
    postprocess::PostProcess,
    op,
    reg::AbstractRegister,
    locs;
    kwargs...,
) where {MODE}
    nbit = nactive(reg)
    focus!(reg, locs)
    res = measure!(postprocess, op, reg, AllLocs(); kwargs...)
    if postprocess isa RemoveMeasured
        relax!(reg; to_nactive = nbit - length(locs))
    else
        relax!(reg, locs; to_nactive = nbit)
    end
    res
end

function measure(
    op,
    reg::AbstractRegister,
    locs;
    kwargs...,
) where {MODE}
    nbit = nactive(reg)
    focus!(reg, locs)
    res = measure(op, reg, AllLocs(); kwargs...)
    relax!(reg, locs; to_nactive = nbit)
    res
end


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
@interface select!(r::AbstractRegister, bits)

"""
    select!(b::Integer) -> f(register)

Lazy version of [`select!`](@ref). See also [`select`](@ref).
"""
select!(bits...) = @λ(register -> select!(register, bits...))

"""
    partial_tr(register, locs)

Return a register which is the partial traced on `locs`.
"""
@interface partial_tr(r::AbstractRegister, locs)

"""
    partial_tr(locs) -> f(register)

Curried version of `partial_tr(register, locs)`.
"""
partial_tr(locs) = @λ(register -> partial_tr(register, locs))

"""
    select(register, bits) -> AbstractRegister

Non-inplace version of [`select!`](@ref).
"""
@interface select(register::AbstractRegister, bits)

"""
    join(::AbstractRegister...) -> register

Merge several registers as one register via tensor product.
"""
@interface Base.join(::AbstractRegister...)

"""
    repeat(r::AbstractRegister, n::Int) -> register

Repeat register `r` for `n` times on batch dimension.
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

Reorder the locations of register by input orders.
"""
@interface reorder!(r::AbstractRegister, orders)

"""
    invorder(register)

Inverse the locations of register.
"""
@interface invorder!(r::AbstractRegister) = reorder!(r, Tuple(nactive(r):-1:1))

"""
    collapseto!(register, config)

Set the `register` to bit string literal `bit_str` (or an equivalent integer). About bit string literal,
see more in [`@bit_str`](@ref).
"""
@interface collapseto!(r::AbstractRegister, config)

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
@interface tracedist(r1::AbstractRegister, r2::AbstractRegister)

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


function Base.iterate(it::AbstractRegister{B}, state = 1) where {B}
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
