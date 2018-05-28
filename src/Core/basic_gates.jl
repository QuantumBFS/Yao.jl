include("identity.jl")

# Constant gates: pauli_x, pauli_y, pauli_z, hardmard, p0, p1, p↑, p↓
const P0 = sparse(Complex128[1 0; 0 0])
const P1 = sparse(Complex128[0 0; 0 1])
const PAULI_X = PermuteMultiply([2,1], [1+0im, 1])
const PAULI_Y = PermuteMultiply([2,1], [-im, im])
const PAULI_Z = Diagonal([1+0im, -1])
const CNOT = PermuteMultiply(Complex128[1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 1 0])
const TOFFOLI = kron(P0, II(4)) + kron(P1, CNOT)

# generate constants and basic_gate interface for different types
ELEM_TYPES = [Complex128, Complex64]
ELEM_TYPE_TOKENS = [:Z, :C]
CONST_MATS = [:PAULI_X, :PAULI_Y, :PAULI_Z]
CONST_LABELS = [:X, :Y, :Z]
CONST_MAT_TYPES = [:PermuteMultiply, :PermuteMultiply, :Diagonal]
for (T, TSTR) in zip(ELEM_TYPES, ELEM_TYPE_TOKENS)
    for (NAME, TOKEN, MT) in zip(CONST_MATS, CONST_LABELS, CONST_MAT_TYPES)
        VARNAME = Symbol(NAME, TSTR)
        V = Val{TOKEN}
        @eval const ($VARNAME) = convert($MT{$T}, ($NAME))
        @eval basic_gate(::Type{$T}, ::Type{$V}) = $VARNAME
    end
end

# pretty interface
for GATE_TYPE in [:basic_gate, :rot_gate]
    @eval $GATE_TYPE(::Type{T}, S::Symbol, params::Number...) where T = $GATE_TYPE(T, Val{S}, params...)
    @eval $GATE_TYPE(S::Symbol, params::Number...) = $GATE_TYPE(Complex128, S, params...)
end

basic_gate(::Type{T}, ::Type{Val{:Rx}}, θ::Real) where T = T[cos(θ/2) -im*sin(θ/2); -im*sin(θ/2) cos(θ/2)]
basic_gate(::Type{T}, ::Type{Val{:Ry}}, θ::Real) where T = T[cos(θ/2) -sin(θ/2); sin(θ/2) cos(θ/2)]
basic_gate(::Type{T}, ::Type{Val{:Rz}}, θ::Real) where T = Diagonal{T}([exp(-im*θ/2), exp(im*θ/2)])

@assert allclose(basic_gate(:Rx, pi), -im*basic_gate(:X))
@assert allclose(basic_gate(:Ry, pi), -im*basic_gate(:Y))
@assert allclose(basic_gate(:Rz, pi), -im*basic_gate(:Z))

basic_gate(::Type{T}, ::Type{Val{:RotZXZ}}, θ1::AbstractFloat, θ2::AbstractFloat, θ3::AbstractFloat) where T = basic_gate(T, :Rz, θ3)*basic_gate(T, :Rx, θ2)*basic_gate(T, :Rz, θ1)

basic_gate(Complex128, :RotZXZ, pi/2, pi/2, 0.0)

# fill other gates
const Pu = nothing
const Pd = nothing
const H = nothing  #dense
