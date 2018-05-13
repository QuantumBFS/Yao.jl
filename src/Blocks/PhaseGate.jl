mutable struct PhiGate{T} <: PrimitiveBlock{1, Complex{T}}
    theta::T
end

full(gate::PhiGate{T}) where T = exp(im * gate.theta) * Complex{T}[exp(-im * gate.theta) 0; 0  exp(im * gate.theta)]

copy(block::PhiGate) = PhiGate(block.theta)
dispatch!(block::PhiGate{T}, theta::T) where T = (block.theta = theta; block)

function dispatch!(block::PhiGate, params::Vector)
    block.theta = pop!(params)
    block
end

# Pretty Printing
function show(io::IO, g::PhiGate{T}) where T
    print(io, "Phase Gate{$T}:", g.theta)
end