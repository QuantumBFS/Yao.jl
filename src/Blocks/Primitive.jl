abstract type AbstractGate{N, T} <: PrimitiveBlock{N, T} end

# a default sparse method
sparse(gate::AbstractGate) = sparse(full(gate))

# TODO: optimize this method later (do not use focus)
function apply!(reg::Register, gate::AbstractGate)
    reg.state .= full(gate) * state(reg)
    reg
end

# Single-Qubit Gates
export X, Y, Z, Hadmard
abstract type GateType end
abstract type X <: GateType end
abstract type Y <: GateType end
abstract type Z <: GateType end
abstract type Hadmard <: GateType end

"""
    Gate{N, GT, T} <: AbstractGate{N, T}

`N` qubits gate whose matrix form is a constant.
"""
struct Gate{N, GT <: GateType, T} <: AbstractGate{N, T} end
Gate(::Type{T}, ::Type{GT}) where {T, GT} = Gate{1, GT, T}()
Gate(::Type{GT}) where GT = Gate(Complex128, GT)

# NOTE: we define some type related constants here to avoid multiple allocation

for (GTYPE, NAME) in [
    (X, "PAULI_X"),
    (Y, "PAULI_Y"),
    (Z, "PAULI_Z"),
    (Hadmard, "HADMARD")
]

    DENSE_NAME = Symbol(join(["CONST", NAME], "_"))
    SPARSE_NAME = Symbol(join(["CONST", "SPARSE", NAME], "_"))

    @eval begin
        full(gate::Gate{1, $GTYPE, T}) where T = $(DENSE_NAME)(T)
        sparse(gate::Gate{1, $GTYPE, T}) where T = $(SPARSE_NAME)(T)
    end

end

mutable struct PhiGate{T} <: AbstractGate{1, Complex{T}}
    theta::T
end

full(gate::PhiGate{T}) where T = exp(im * gate.theta) * Complex{T}[exp(-im * gate.theta) 0; 0  exp(im * gate.theta)]

copy(block::PhiGate) = PhiGate(block.theta)
dispatch!(block::PhiGate{T}, theta::T) where T = (block.theta = theta; block)

function dispatch!(block::PhiGate, params::Vector)
    block.theta = pop!(params)
    block
end

import Base: ==, hash
==(lhs::PhiGate, rhs::PhiGate) = lhs.theta == rhs.theta

function hash(gate::PhiGate, h::UInt)
    hash(hash(gate.theta, object_id(gate)), h)
end

###########
# Rotation
###########

mutable struct RotationGate{GT, T} <: AbstractGate{1, Complex{T}}
    theta::T
end

# TODO: implement arbitrary rotation: cos(theta/2) - im * sin(theta/2) * U

full(gate::RotationGate{X, T}) where T =
    Complex{T}[cos(gate.theta/2) -im*sin(gate.theta/2);
      -im*sin(gate.theta/2) cos(gate.theta/2)]
full(gate::RotationGate{Y, T}) where T =
    Complex{T}[cos(gate.theta/2) -sin(gate.theta/2);
      sin(gate.theta/2) cos(gate.theta/2)]
full(gate::RotationGate{Z, T}) where T =
    Complex{T}[exp(-im*gate.theta/2) 0;0 exp(im*gate.theta/2)]

copy(block::RotationGate{GT, T}) where {GT, T} = RotationGate{GT, T}(block.theta)

# TODO: dispatch a vector
dispatch!(block::RotationGate{GT, T}, theta::T) where {GT, T} = (block.theta = theta; block)

function dispatch!(block::RotationGate, theta::Vector)
    block.theta = pop!(theta)
    block
end

import Base: ==, hash
==(lhs::RotationGate{GT}, rhs::RotationGate{GT}) where GT = lhs.theta == rhs.theta

function hash(gate::RotationGate, h::UInt)
    hash(hash(gate.theta, object_id(gate)), h)
end

# TODO:
# 1. new Primitive: SWAP gate


##################
# Pretty Printing
##################

for (GTYPE, NAME) in [
    (X, "X"),
    (Y, "Y"),
    (Z, "Z"),
    (Hadmard, "Hadmard")
]

@eval begin
    function show(io::IO, block::Gate{1, $GTYPE, T}) where T
        print(io, $(NAME), "{$T}")
    end
end

end

function show(io::IO, g::PhiGate{T}) where T
    print(io, "Phase Gate{$T}:", g.theta)
end

for (GTYPE, NAME) in [
    (X, "Rx"),
    (Y, "Ry"),
    (Z, "Rz"),
]

    @eval begin
        function show(io::IO, g::RotationGate{$GTYPE, T}) where T
            print(io, $NAME, "{", T, "}: ", g.theta)
        end
    end

end
