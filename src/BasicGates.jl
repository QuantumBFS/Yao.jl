export Gate, X, Y, Z

"""
    AbstractGateType{N}

Gate types denote each specific gate, while subtypes of
AbstractGate denotes the memory structure.
"""
abstract type AbstractGateType{N} end
abstract type X <: AbstractGateType{1} end
abstract type Y <: AbstractGateType{1} end
abstract type Z <: AbstractGateType{1} end
abstract type H <: AbstractGateType{1} end
abstract type CNOT <: AbstractGateType{2} end

"""
    Gate{GT, N} <: AbstractGate{N}

simple qubit gate without any parameters,
GT is the type of gate, e.g: X, Y, Z, H
"""
struct Gate{GT, N} <: AbstractGate{N} end

# constructor short cuts
gate(::Type{GT}) where {GT <: AbstractGateType{1}} = Gate{GT, 1}()
gate(::Type{GT}) where {GT <: AbstractGateType{2}} = Gate{GT, 2}()

sparse(::Type{T}, gate::Gate) where T = sparse(full(T, gate))

# matrix forms
full(::Type{T}, gate::Gate{X}) where T = T[0 1;1 0]
full(::Type{T}, gate::Gate{Y}) where T = T[0 -im; im 0]
full(::Type{T}, gate::Gate{Z}) where T = T[1 0;0 -1]

function full(::Type{T}, gate::Gate{H}) where T
    elem = T(1 / sqrt(2))
    T[elem elem; elem -elem]
end
