export PhaseGate

"""
    PhiGate

Global phase gate.
"""
mutable struct PhaseGate{T} <: PrimitiveBlock{1, Complex{T}}
    theta::T
end

mat(gate::PhaseGate{T}) where T = exp(im * gate.theta) * IMatrix{2, Complex{T}}()

copy(block::PhaseGate{T}) where T = PhaseGate{T}(block.theta)
dispatch!(f::Function, block::PhaseGate, theta) = (block.theta = f(block.theta, theta); block)

# Properties
nparameters(::PhaseGate) = 1

==(lhs::PhaseGate, rhs::PhaseGate) = lhs.theta == rhs.theta

function hash(gate::PhaseGate, h::UInt)
    hash(hash(gate.theta, objectid(gate)), h)
end

function print_block(io::IO, g::PhaseGate)
    print(io, "Global Phase Gate:", g.theta)
end
