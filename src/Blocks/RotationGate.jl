export RotationGate

mutable struct RotationGate{T, GT <: PrimitiveBlock{1, Complex{T}}} <: PrimitiveBlock{1, Complex{T}}
    U::GT
    theta::T
end

_make_rot_mat(I, U, theta) = I * cos(theta / 2) - im * sin(theta / 2) * U
mat(R::RotationGate{T, GT}) where {T, GT} = _make_rot_mat(IMatrix{2, Complex{T}}(), mat(R.U), R.theta)

copy(R::RotationGate{T, GT}) where {T, GT} = RotationGate{T, GT}(R.U, R.theta)

function dispatch!(R::RotationGate, theta)
    R.theta = theta
    R
end

# Properties
nparameters(::Type{<:RotationGate}) = 1
parameters(x::RotationGate) = x.theta

==(lhs::RotationGate{TA, GTA}, rhs::RotationGate{TB, GTB}) where {TA, TB, GTA, GTB} = false
==(lhs::RotationGate{TA, GT}, rhs::RotationGate{TB, GT}) where {TA, TB, GT} = lhs.theta == rhs.theta

function hash(gate::RotationGate{T, GT}, h::UInt) where {T, GT}
    hashkey = hash(objectid(gate), h)
    hashkey = hash(gate.theta, hashkey)
    hashkey = hash(gate.U, hashkey)
    hashkey
end

cache_key(R::RotationGate) = R.theta

function print_block(io::IO, R::RotationGate)
    print(io, "Rot ", R.U, ": ", R.theta)
end
