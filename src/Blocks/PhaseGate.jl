export PhaseGate

"""
    PhiGate

Global phase gate.
"""
mutable struct PhaseGate{T} <: PrimitiveBlock{1, Complex{T}}
    theta::T
end

mat(gate::PhaseGate{T}) where T = exp(im * gate.theta) * IMatrix{2, Complex{T}}()
adjoint(blk::PhaseGate) = PhaseGate(-blk.theta)

copy(block::PhaseGate{T}) where T = PhaseGate{T}(block.theta)
dispatch!(block::PhaseGate, theta) = (block.theta = theta; block)

# Properties
nparameters(::Type{<:PhaseGate}) = 1
parameters(x::PhaseGate) = x.theta

==(lhs::PhaseGate, rhs::PhaseGate) = lhs.theta == rhs.theta

function hash(gate::PhaseGate, h::UInt)
    hash(hash(gate.theta, objectid(gate)), h)
end

cache_key(gate::PhaseGate) = gate.theta

function print_block(io::IO, g::PhaseGate)
    print(io, "Global Phase Gate:", g.theta)
end
