export PhaseGate, phase

"""
    PhaseGate

Global phase gate.
"""
mutable struct PhaseGate{T} <: PrimitiveBlock{2}
    theta::T
end
nqudits(pg::PhaseGate) = 1

"""
    phase(theta)

Returns a global phase gate. Defined with following matrix form:

```math
e^{iθ} I
```

### Examples

You can create a global phase gate with a phase (a real number).

```jldoctest; setup=:(using YaoBlocks)
julia> phase(0.1)
phase(0.1)
```
"""
phase(θ::Real) = PhaseGate(θ)

mat(::Type{T}, gate::PhaseGate) where {T} = exp(T(im * gate.theta)) * IMatrix{T}(2)

# parametric interface
niparams(::Type{<:PhaseGate}) = 1
getiparams(x::PhaseGate) = x.theta
setiparams!(r::PhaseGate, param::Number) = (r.theta = param; r)
setiparams(r::PhaseGate, param::Number) = PhaseGate(param)

# fallback to matrix method if it is not real
YaoAPI.isunitary(r::PhaseGate{<:Real}) = true

function YaoAPI.isunitary(r::PhaseGate)
    isreal(r.theta) && return true
    @warn "θ in phase(θ) is not real, got $(r.theta), fallback to matrix-based method"
    return isunitary(mat(r))
end
YaoAPI.isdiagonal(r::PhaseGate) = true

Base.adjoint(blk::PhaseGate) = PhaseGate(-blk.theta)
Base.copy(block::PhaseGate{T}) where {T} = PhaseGate{T}(block.theta)
Base.:(==)(lhs::PhaseGate, rhs::PhaseGate) = lhs.theta == rhs.theta

cache_key(gate::PhaseGate) = gate.theta

function iparams_range(::PhaseGate{T}) where {T}
    return ((zero(T), T(2.0 * pi)),)
end
