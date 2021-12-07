using YaoBase

export PhaseGate, phase

"""
    PhiGate

Global phase gate.
"""
mutable struct PhaseGate{T} <: PrimitiveBlock{1}
    theta::T
end

"""
    phase(theta)

Returns a global phase gate. Defined with following matrix form:

```math
e^{iθ} \\mathbf{I}
```

# Example

You can create a global phase gate with a phase (a real number).

```jldoctest; setup=:(using YaoBlocks)
julia> phase(0.1)
phase(0.1)
```
"""
phase(θ::Real) = PhaseGate(θ)

mat(::Type{T}, gate::PhaseGate) where {T} = exp(T(im * gate.theta)) * IMatrix{2,T}()

# parametric interface
niparams(::Type{<:PhaseGate}) = 1
getiparams(x::PhaseGate) = x.theta
setiparams!(r::PhaseGate, param::Number) = (r.theta = param; r)
setiparams(r::PhaseGate, param::Number) = PhaseGate(param)

# fallback to matrix method if it is not real
YaoBase.isunitary(r::PhaseGate{<:Real}) = true

function YaoBase.isunitary(r::PhaseGate)
    isreal(r.theta) && return true
    @warn "θ in phase(θ) is not real, got $(r.theta), fallback to matrix-based method"
    return isunitary(mat(r))
end

Base.adjoint(blk::PhaseGate) = PhaseGate(-blk.theta)
Base.copy(block::PhaseGate{T}) where {T} = PhaseGate{T}(block.theta)
Base.:(==)(lhs::PhaseGate, rhs::PhaseGate) = lhs.theta == rhs.theta

cache_key(gate::PhaseGate) = gate.theta

function parameters_range!(out::Vector{Tuple{T,T}}, gate::PhaseGate{T}) where {T}
    push!(out, (0.0, 2.0 * pi))
end
