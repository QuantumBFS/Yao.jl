using YaoBase

export ShiftGate, shift

"""
    ShiftGate <: PrimitiveBlock

Phase shift gate.
"""
mutable struct ShiftGate{T} <: PrimitiveBlock{1, Complex{T}}
    theta::T
end

"""
    shift(θ)

Returns a shift gate.
"""
shift(θ::AbstractFloat) = ShiftGate(θ)
mat(gate::ShiftGate{T}) where T = Diagonal(Complex{T}[1.0, exp(im * gate.theta)])

cache_key(gate::ShiftGate) = gate.theta

# parametric interface
nparameters(::Type{<:ShiftGate}) = 1
parameters(x::ShiftGate) = x.theta
setparameters!(r::ShiftGate, param::Real) = (r.theta = param; r)


Base.adjoint(blk::ShiftGate) = ShiftGate(-blk.theta)
Base.copy(block::ShiftGate{T}) where T = ShiftGate{T}(block.theta)
Base.:(==)(lhs::ShiftGate, rhs::ShiftGate) = lhs.theta == rhs.theta
YaoBase.isunitary(r::ShiftGate) = true
