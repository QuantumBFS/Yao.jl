export RotationGate

"""
    RotationGate{N, T, GT <: MatrixBlock{N, Complex{T}}} <: MatrixBlock{N, Complex{T}}

RotationGate, with GT both hermitian and isreflexive.
"""
mutable struct RotationGate{N, T, GT <: MatrixBlock{N, Complex{T}}} <: PrimitiveBlock{N, Complex{T}}
    U::GT
    theta::T
    function RotationGate{N, T, GT}(U::GT, theta) where {N, T, GT <: MatrixBlock{N, Complex{T}}}
        ishermitian(U) && isreflexive(U) || throw(ArgumentError("Gate type $GT is not hermitian or not isreflexive!"))
        new{N, T, GT}(U, T(theta))
    end
end
RotationGate(U::GT, theta) where {N, T, GT<:MatrixBlock{N, Complex{T}}} = RotationGate{N, T, GT}(U, theta)

_make_rot_mat(I, U, theta) = I * cos(theta / 2) - im * sin(theta / 2) * U
mat(R::RotationGate{N, T}) where {N, T} = _make_rot_mat(IMatrix{1<<N, Complex{T}}(), mat(R.U), R.theta)
mat(R::RotationGate{N, T, <:Union{XGate, YGate}}) where {N, T} = _make_rot_mat(IMatrix{1<<N, Complex{T}}(), mat(R.U), R.theta) |> Matrix
adjoint(blk::RotationGate) = RotationGate(blk.U, -blk.theta)

copy(R::RotationGate) = RotationGate(R.U, R.theta)

function dispatch!(R::RotationGate, itr)
    R.theta = first(itr)
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
