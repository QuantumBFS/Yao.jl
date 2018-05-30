export PhaseGate

"""
    PhiGate

Global phase gate.
"""
mutable struct PhaseGate{PhaseType, T} <: PrimitiveBlock{1, Complex{T}}
    theta::T
end

mat(gate::PhaseGate{:global, T}) where T = exp(im * gate.theta) * Const.Sparse.I2(T)
mat(gate::PhaseGate{:shift, T}) where T = Complex{T}[1.0 0.0;0.0 exp(im * gate.theta)]

copy(block::PhaseGate{PhaseType, T}) where {PhaseType, T} = PhaseGate{PhaseType, T}(block.theta)
dispatch!(f::Function, block::PhaseGate, theta) = (block.theta = f(block.theta, theta); block)

# Properties
nparameters(::PhaseGate) = 1

==(lhs::PhaseGate, rhs::PhaseGate) = false
==(lhs::PhaseGate{PT}, rhs::PhaseGate{PT}) where PT = lhs.theta == rhs.theta

function hash(gate::PhaseGate, h::UInt)
    hash(hash(gate.theta, object_id(gate)), h)
end
