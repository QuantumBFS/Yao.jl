using YaoBase

export PhaseGate, phase

"""
    PhiGate

Global phase gate.
"""
mutable struct PhaseGate{T <: Real} <: PrimitiveBlock{1}
    theta::T
end

"""
    phase(theta)

Returns a global phase gate. Defined with following matrix form:

```math
exp(iθ) \\mathbf{I}
```

# Example

You can create a global phase gate with a phase (a real number).

```jldoctest; setup=:(using YaoBlocks)
julia> phase(0.1)
phase(0.1)
```
"""
phase(θ::AbstractFloat) = PhaseGate(θ)
phase(θ::Real) = phase(Float64(θ))

mat(::Type{T}, gate::PhaseGate) where T = exp(T(im * gate.theta)) * IMatrix{2, T}()

# parametric interface
niparams(::Type{<:PhaseGate}) = 1
getiparams(x::PhaseGate) = x.theta
setiparams!(r::PhaseGate, param::Real) = (r.theta = param; r)

YaoBase.isunitary(r::PhaseGate) = true
Base.adjoint(blk::PhaseGate) = PhaseGate(-blk.theta)
Base.copy(block::PhaseGate{T}) where T = PhaseGate{T}(block.theta)
Base.:(==)(lhs::PhaseGate, rhs::PhaseGate) = lhs.theta == rhs.theta

cache_key(gate::PhaseGate) = gate.theta
