using YaoBase

export PhaseGate, phase

"""
    PhiGate

Global phase gate.
"""
mutable struct PhaseGate{T} <: PrimitiveBlock{1, Complex{T}}
    theta::T
end

"""
    phase(theta)

Returns a global phase gate.
"""
phase(θ::AbstractFloat) = PhaseGate(θ)
mat(gate::PhaseGate{T}) where T = exp(im * gate.theta) * IMatrix{2, Complex{T}}()

# parametric interface
niparameters(::Type{<:PhaseGate}) = 1
iparameters(x::PhaseGate) = x.theta
setiparameters!(r::PhaseGate, param::Real) = (r.theta = param; r)

YaoBase.isunitary(r::PhaseGate) = true
Base.adjoint(blk::PhaseGate) = PhaseGate(-blk.theta)
Base.copy(block::PhaseGate{T}) where T = PhaseGate{T}(block.theta)
Base.:(==)(lhs::PhaseGate, rhs::PhaseGate) = lhs.theta == rhs.theta

cache_key(gate::PhaseGate) = gate.theta
