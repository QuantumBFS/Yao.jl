using Compat: ComplexF64, ComplexF32
using Compat.SparseArrays

# Constant gates: pauli_x, pauli_y, pauli_z, hardmard, p0, p1, p↑, p↓
const P0 = sparse(ComplexF64[1 0; 0 0])
const P1 = sparse(ComplexF64[0 0; 0 1])
const PAULI_X = PermMatrix([2,1], [1+0im, 1])
const PAULI_Y = PermMatrix([2,1], [-im, im])
const PAULI_Z = Diagonal([1+0im, -1])
const CNOT_MAT = PermMatrix(ComplexF64[1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 1 0])
const TOFFOLI_MAT = kron(P0, II(4)) + kron(P1, CNOT_MAT)
const Pu = sparse([1], [2], [1+0im], 2, 2)
const Pd = sparse([2], [1], [1+0im], 2, 2)
const H_MAT = ComplexF64[1 1; 1 -1]

# generate constants and basic_gate interface for different types
ELEM_TYPES = [ComplexF64, ComplexF32]
ELEM_TYPE_TOKENS = [:Z, :C]
CONST_MATS = [:PAULI_X, :PAULI_Y, :PAULI_Z]
CONST_MAT_TYPES = [:PermMatrix, :PermMatrix, :Diagonal]
for (T, TSTR) in zip(ELEM_TYPES, ELEM_TYPE_TOKENS)
    for (NAME, MT) in zip(CONST_MATS, CONST_MAT_TYPES)
        VARNAME = Symbol(NAME, TSTR)
        @eval const ($VARNAME) = convert($MT{$T}, ($NAME))
    end
end

#= TODO: Merge
# pretty interface
for GATE_TYPE in [:basic_gate, :rot_gate]
    @eval $GATE_TYPE(::Type{T}, S::Symbol, params::Number...) where T = $GATE_TYPE(T, Val{S}, params...)
    @eval $GATE_TYPE(S::Symbol, params::Number...) = $GATE_TYPE(ComplexF64, S, params...)
end

basic_gate(::Type{T}, ::Type{Val{:Rx}}, θ::Real) where T = T[cos(θ/2) -im*sin(θ/2); -im*sin(θ/2) cos(θ/2)]
basic_gate(::Type{T}, ::Type{Val{:Ry}}, θ::Real) where T = T[cos(θ/2) -sin(θ/2); sin(θ/2) cos(θ/2)]
basic_gate(::Type{T}, ::Type{Val{:Rz}}, θ::Real) where T = Diagonal{T}([exp(-im*θ/2), exp(im*θ/2)])

@assert allclose(basic_gate(:Rx, pi), -im*basic_gate(:X))
@assert allclose(basic_gate(:Ry, pi), -im*basic_gate(:Y))
@assert allclose(basic_gate(:Rz, pi), -im*basic_gate(:Z))

basic_gate(::Type{T}, ::Type{Val{:RotZXZ}}, θ1::AbstractFloat, θ2::AbstractFloat, θ3::AbstractFloat) where T = basic_gate(T, :Rz, θ3)*basic_gate(T, :Rx, θ2)*basic_gate(T, :Rz, θ1)

basic_gate(ComplexF64, :RotZXZ, pi/2, pi/2, 0.0)

# fill other gates
const Pu = nothing
const Pd = nothing
const H = nothing  #dense
=#
