using QuCircuit
import QuCircuit: gate, PrimitiveBlock, GateType

mutable struct RotBasis{MT, PT} <: PrimitiveBlock{1, MT}
    theta::MT
    phi::PT
end

gate(::Type{Complex{T}}, ::Type{GateType{RotBasis}}, theta::T, phi::T) where T = RotBasis{Complex{T}, T}(theta, phi)
