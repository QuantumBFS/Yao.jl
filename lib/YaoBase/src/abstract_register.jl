using BitBasis, LegibleLambdas

export @λ, @lambda

# same with nbatch
Base.length(r::AbstractRegister{B}) where {B} = B

addbits!(n::Int) = @λ(register -> addbits!(register, n))
insert_qubits!(loc::Int; nqubits::Int = 1) =
    @λ(register -> insert_qubits!(register, loc; nqubits = n))

nremain(r::AbstractRegister) = nqubits(r) - nactive(r)
nbatch(r::AbstractRegister{B}) where {B} = B

"""
    focus!(locs...) -> f(register) -> register

Lazy version of [`focus!`](@ref), this returns a lambda which requires a register.
"""
focus!(locs::Int...) = focus!(locs)
focus!(locs::NTuple{N,Int}) where {N} = @λ(register -> focus!(register, locs))
focus!(locs::UnitRange) = @λ(register -> focus!(register, locs))

relax!(r::AbstractRegister; to_nactive::Int = nqubits(r)) =
    relax!(r, (); to_nactive = to_nactive)

"""
    relax!(locs::Int...; to_nactive=nqubits(register)) -> f(register) -> register

Lazy version of [`relax!`](@ref), it will be evaluated once you feed a register
to its output lambda.
"""
relax!(locs::Int...; to_nactive::Union{Nothing,Int} = nothing) =
    relax!(locs; to_nactive = to_nactive)

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
        return LegibleLambda(:(register -> relax!(register, locs...; to_nactive)), lambda)
    end
end

## Measurement
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
measure(reg::AbstractRegister, locs; kwargs...) =
    measure(ComputationalBasis(), reg, locs; kwargs...)
measure(reg::AbstractRegister; kwargs...) =
    measure(ComputationalBasis(), reg, AllLocs(); kwargs...)

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

function measure(op, reg::AbstractRegister, locs; kwargs...) where {MODE}
    nbit = nactive(reg)
    focus!(reg, locs)
    res = measure(op, reg, AllLocs(); kwargs...)
    relax!(reg, locs; to_nactive = nbit)
    res
end


"""
    basis(register) -> UnitRange

Returns an `UnitRange` of the all the bits in the Hilbert space of given register.
"""
BitBasis.basis(r::AbstractRegister) = basis(nqubits(r))

invorder!(r::AbstractRegister) = reorder!(r, Tuple(nactive(r):-1:1))

"""
    partial_tr(locs) -> f(register)

Curried version of `partial_tr(register, locs)`.
"""
partial_tr(locs) = @λ(register -> partial_tr(register, locs))

"""
    select!(b::Integer) -> f(register)

Lazy version of [`select!`](@ref). See also [`select`](@ref).
"""
select!(bits...) = @λ(register -> select!(register, bits...))

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

ρ(x) = density_matrix(x)
