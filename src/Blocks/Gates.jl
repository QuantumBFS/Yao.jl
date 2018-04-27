abstract type AbstractGate{N} <: LeafBlock{N} end

function apply!(gate::AbstractGate{N}, reg::Register{M, 1}, head::Int=1) where {N, M}
    focused_reg = focus(reg, head:head+N)
    reg.state .= reshape(full(gate) * state(focused_reg), size(reg.state))
    reg
end

function apply!(gate::AbstractGate{N}, reg::Register{M, B}, head::Int=1) where {N, M, B}
    focused_reg = focus(reg, head:head+N)
    # TODO: parallelize this
    for i = 1:B
        each = view_batch(reg, i)
        reg.state[[Colon() for i=1:M]..., i] = reshape(full(gate) * each, size(reg.state, 1:M...))
    end
    reg
end

# Pauli Gates
abstract type Pauli end
abstract type X <: Pauli end
abstract type Y <: Pauli end
abstract type Z <: Pauli end
# Hadmard
abstract type Hadmard end

"""
    Gate{N, G} <: AbstractGate{N}

gate with no parameters. overload its
constructor and `full`/`sparse` to
support you own gates.
"""
struct Gate{N, G} <: AbstractGate{N} end
Gate(::Type{T}) where {T <: Pauli} = Gate{1, T}()
Gate(::Type{Hadmard}) = Gate{1, Hadmard}()

sparse(::Type{T}, gate::Gate) where T = sparse(full(gate))

# NOTE: we define some type related constants here to avoid extra allocation
import Compat
for (NAME, DType) in [
        (:ComplexF64, Compat.ComplexF64),
        (:ComplexF32, Compat.ComplexF32),
        (:ComplexF16, Compat.ComplexF16),
    ]
    
    @eval begin
        const $(Symbol(join(["CONST", "PAULI", "X", NAME], "_"))) = $DType[0 1;1 0]
        const $(Symbol(join(["CONST", "PAULI", "Y", NAME], "_"))) = $DType[0 -im; im 0]
        const $(Symbol(join(["CONST", "PAULI", "Z", NAME], "_"))) = $DType[1 0;0 -1]
        const $(Symbol(join(["CONST", "HADMARD", NAME], "_"))) = (elem = $DType(1 / sqrt(2)); $DType[elem elem; elem -elem])

        const $(Symbol(join(["CONST", "SPARSE", "PAULI", "X", NAME], "_"))) = $DType[0 1;1 0]
        const $(Symbol(join(["CONST", "SPARSE", "PAULI", "Y", NAME], "_"))) = $DType[0 -im; im 0]
        const $(Symbol(join(["CONST", "SPARSE", "PAULI", "Z", NAME], "_"))) = $DType[1 0;0 -1]
        const $(Symbol(join(["CONST", "SPARSE", "HADMARD", NAME], "_"))) = (elem = $DType(1 / sqrt(2)); $DType[elem elem; elem -elem])

        full(::Type{$DType}, gate::Gate{1, X}) = $(Symbol(join(["CONST", "PAULI", "X", NAME], "_")))
        full(::Type{$DType}, gate::Gate{1, Y}) = $(Symbol(join(["CONST", "PAULI", "Y", NAME], "_")))
        full(::Type{$DType}, gate::Gate{1, Z}) = $(Symbol(join(["CONST", "PAULI", "Z", NAME], "_")))
        full(::Type{$DType}, gate::Gate{1, Hadmard}) = $(Symbol(join(["CONST", "HADMARD", NAME], "_")))

        sparse(::Type{$DType}, gate::Gate{1, X}) = $(Symbol(join(["CONST", "SPARSE", "PAULI", "X", NAME], "_")))
        sparse(::Type{$DType}, gate::Gate{1, Y}) = $(Symbol(join(["CONST", "SPARSE", "PAULI", "Y", NAME], "_")))
        sparse(::Type{$DType}, gate::Gate{1, Z}) = $(Symbol(join(["CONST", "SPARSE", "PAULI", "Z", NAME], "_")))
        sparse(::Type{$DType}, gate::Gate{1, Hadmard}) = $(Symbol(join(["CONST", "SPARSE", "HADMARD", NAME], "_")))
    end
end

# NOTE: This is a fallback method for other types
#       However, this will allocate new memory each
#       time it is called
full(::Type{T}, gate::Gate{1, X}) where T = T[0 1;1 0]
full(::Type{T}, gate::Gate{1, Y}) where T = T[0 -im; im 0]
full(::Type{T}, gate::Gate{1, Z}) where T = T[1 0;0 -1]
full(::Type{T}, gate::Gate{1, Hadmard}) where T = (elem = T(1 / sqrt(2)); T[elem elem; elem -elem])

struct PhiGate{T}
    theta::T
end

full(::Type{T}, gate::PhiGate) where T =
    exp(im * gate.theta) * T[exp(-im * gate.theta) 0;
                             0  exp(im * gate.theta)]

struct RGate{G, T} <: AbstractGate{1}
    theta::T
end

full(::Type{T}, gate::RGate{X}) where T =
    T[cos(gate.theta/2) -im*sin(gate.theta/2);
      -im*sin(gate.theta/2) cos(gate.theta/2)]
full(::Type{T}, gate::RGate{Y}) where T =
    T[cos(gate.theta/2) -sin(gate.theta/2);
      sin(gate.theta/2) cos(gate.theta/2)]
full(::Type{T}, gate::RGate{Z}) where T =
    T[exp(-im*gate.theta/2) 0;0 exp(im*gate.theta/2)]
