mutable struct PhiGate{T} <: PrimitiveBlock{1, Complex{T}}
    theta::T
end

sparse(gate::PhiGate) = sparse(full(gate))
full(gate::PhiGate{T}) where T = exp(im * gate.theta) * Complex{T}[exp(-im * gate.theta) 0; 0  exp(im * gate.theta)]

copy(block::PhiGate) = PhiGate(block.theta)
dispatch!(f::Function, block::PhiGate{T}, theta::T) where T = (block.theta = f(block.theta, theta); block)

# Properties
isreflexive(::PhiGate) = false
ishermitian(::PhiGate) = false
nparameters(::PhiGate) = 1

# Pretty Printing
function show(io::IO, g::PhiGate{T}) where T
    print(io, "Phase Gate{$T}:", g.theta)
end