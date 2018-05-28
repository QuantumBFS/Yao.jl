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
isreflexive(::PhaseGate) = false
ishermitian(::PhaseGate) = false
nparameters(::PhaseGate) = 1

# Pretty Printing
function show(io::IO, g::PhaseGate{:global})
    print(io, "Global Phase Gate:", g.theta)
end

function show(io::IO, g::PhaseGate{:shift})
    print(io, "Phase Shift Gate:", g.theta)
end
