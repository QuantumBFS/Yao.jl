abstract type AbstractGate{N, T} <: PrimitiveBlock{N, T} end

# a default sparse method
sparse(gate::AbstractGate) = sparse(full(gate))

# TODO: optimize this method later (do not use focus)
function apply!(reg::Register, gate::AbstractGate)
    reg.state .= full(gate) * state(reg)
    reg
end

# Single-Qubit Gates
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

export gate
"""
    gate(type, gate_type)
    gate(gate_type)

Create an instance of `gate_type`.

### Example

create a Pauli X gate: `gate(X)`
"""
gate = Gate

# NOTE: we define some type related constants here to avoid multiple allocation

import Compat

for (GTYPE, NAME, MAT) in [
    (X, "PAULI_X", [0 1;1 0]),
    (Y, "PAULI_Y", [0 -im; im 0]),
    (Z, "PAULI_Z", [1 0;0 -1]),
    (Hadmard, "HADMARD", (elem = 1 / sqrt(2); [elem elem; elem -elem]))
]

    for (TYPE_NAME, DTYPE) in [
        ("ComplexF16", Compat.ComplexF16),
        ("ComplexF32", Compat.ComplexF32),
        ("ComplexF64", Compat.ComplexF64),
    ]

        @eval begin

            const $(Symbol(join(["CONST", NAME, TYPE_NAME], "_"))) = Array{$DTYPE, 2}($MAT)
            const $(Symbol(join(["CONST", "SPARSE", NAME, TYPE_NAME], "_"))) = sparse(Array{$DTYPE, 2}($MAT))

            full(gate::Gate{1, $GTYPE, $DTYPE}) = $(Symbol(join(["CONST", NAME, TYPE_NAME], "_")))
            sparse(gate::Gate{1, $GTYPE, $DTYPE}) = $(Symbol(join(["CONST", "SPARSE", NAME, TYPE_NAME])))
        end

    end

    @eval begin
        # fallback method for other types
        full(gate::Gate{1, $GTYPE, T}) where T = Array{T, 2}(MAT)
    end

end

mutable struct PhiGate{T} <: AbstractGate{1, T}
    theta::T
end

export phase
phase(theta) = PhiGate(theta)
full(gate::PhiGate{T}) where T = exp(im * gate.theta) * T[exp(-im * gate.theta) 0; 0  exp(im * gate.theta)]

copy(block::PhiGate) = PhiGate(block.theta)
update!(block::PhiGate{T}, theta::T) where T = (block.theta = theta; block)

mutable struct RotationGate{GT, T} <: AbstractGate{1, T}
    theta::T
end

full(gate::RotationGate{X, T}) where T =
    T[cos(gate.theta/2) -im*sin(gate.theta/2);
      -im*sin(gate.theta/2) cos(gate.theta/2)]
full(gate::RotationGate{Y, T}) where T =
    T[cos(gate.theta/2) -sin(gate.theta/2);
      sin(gate.theta/2) cos(gate.theta/2)]
full(gate::RotationGate{Z, T}) where T =
    T[exp(-im*gate.theta/2) 0;0 exp(im*gate.theta/2)]

copy(block::RotationGate{GT, T}) where {GT, T} = RotationGate{GT, T}(block.theta)
update!(block::RotationGate{GT, T}, theta::T) where {GT, T} = (block.theta = theta; block)
