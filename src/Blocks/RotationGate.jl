export RotationGate

"""
    RotationGate{N, T, GT <: MatrixBlock{N, Complex{T}}} <: PrimitiveBlock{N, Complex{T}}

RotationGate, with GT both hermitian and isreflexive.
"""
mutable struct RotationGate{N, T, GT <: MatrixBlock{N, Complex{T}}} <: PrimitiveBlock{N, Complex{T}}
    block::GT
    theta::T
    function RotationGate{N, T, GT}(block::GT, theta) where {N, T, GT <: MatrixBlock{N, Complex{T}}}
        ishermitian(block) && isreflexive(block) || throw(ArgumentError("Gate type $GT is not hermitian or not isreflexive!"))
        new{N, T, GT}(block, T(theta))
    end
end
RotationGate(block::GT, theta) where {N, T, GT<:MatrixBlock{N, Complex{T}}} = RotationGate{N, T, GT}(block, theta)

# block(rt::RotationGate) = rt.block
# setblock!(rt::RotationGate{<:Any, <:Any, GT}, blk::GT) where GT = (rt.block = blk; rt)

_make_rot_mat(I, block, theta) = I * cos(theta / 2) - im * sin(theta / 2) * block
mat(R::RotationGate{N, T}) where {N, T} = _make_rot_mat(IMatrix{1<<N, Complex{T}}(), mat(R.block), R.theta)
mat(R::RotationGate{N, T, <:Union{XGate, YGate}}) where {N, T} = _make_rot_mat(IMatrix{1<<N, Complex{T}}(), mat(R.block), R.theta) |> Matrix
adjoint(blk::RotationGate) = RotationGate(blk.block, -blk.theta)

function apply!(reg::DefaultRegister, rb::RotationGate)
    v0 = copy(reg.state)
    apply!(reg, rb.block)
    reg.state = -im*sin(rb.theta/2)*reg.state + cos(rb.theta/2)*v0
    reg
end

copy(R::RotationGate) = RotationGate(R.block, R.theta)

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
    hashkey = hash(gate.block, hashkey)
    hashkey
end

cache_key(R::RotationGate) = R.theta

function print_block(io::IO, R::RotationGate)
    print(io, "Rot ", R.block, ": ", R.theta)
end
