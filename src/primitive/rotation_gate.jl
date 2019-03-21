using YaoBase, YaoArrayRegister
import StaticArrays: SMatrix
export RotationGate, Rx, Ry, Rz, rot

"""
    RotationGate{N, T, GT <: AbstractBlock{N, Complex{T}}} <: PrimitiveBlock{N, Complex{T}}

RotationGate, with GT both hermitian and isreflexive.
"""
mutable struct RotationGate{N, T, GT <: AbstractBlock{N, Complex{T}}} <: PrimitiveBlock{N, Complex{T}}
    block::GT
    theta::T
    function RotationGate{N, T, GT}(block::GT, theta) where {N, T, GT <: AbstractBlock{N, Complex{T}}}
        ishermitian(block) && isreflexive(block) ||
            throw(ArgumentError("Gate type $GT is not hermitian or not isreflexive."))
        new{N, T, GT}(block, T(theta))
    end
end

RotationGate(block::GT, theta) where {N, T, GT<:AbstractBlock{N, Complex{T}}} = RotationGate{N, T, GT}(block, T(theta))

# bindings
"""
    Rx(theta)

Return a [`RotationGate`](@ref) on X axis.
"""
Rx(theta::T) where T <: AbstractFloat = RotationGate(X(Complex{T}), theta)

"""
    Ry(theta)

Return a [`RotationGate`](@ref) on Y axis.
"""
Ry(theta::T) where T <: AbstractFloat = RotationGate(Y(Complex{T}), theta)

"""
    Rz(theta)

Return a [`RotationGate`](@ref) on Z axis.
"""
Rz(theta::T) where T <: AbstractFloat = RotationGate(Z(Complex{T}), theta)

"""
    rot(U, theta)

Return a [`RotationGate`](@ref) on U axis.
"""
rot(axis::AbstractBlock, theta) = RotationGate(axis, theta)

content(x::RotationGate) = x.block
# General definition
function mat(R::RotationGate{N, T}) where {N, T}
    I = IMatrix{1<<N, Complex{T}}()
    return I * cos(R.theta / 2) - im * sin(R.theta / 2) * mat(R.block)
end

# Specialized
mat(R::RotationGate{1, T, XGate{Complex{T}}}) where T =
    SMatrix{2, 2, Complex{T}}(cos(R.theta/2), -im * sin(R.theta/2), -im * sin(R.theta/2), cos(R.theta/2))
mat(R::RotationGate{1, T, YGate{Complex{T}}}) where T =
    SMatrix{2, 2, Complex{T}}(cos(R.theta/2), sin(R.theta/2), -sin(R.theta/2), cos(R.theta/2))
mat(R::RotationGate{1, T, ZGate{Complex{T}}}) where T =
    SMatrix{2, 2, Complex{T}}(cos(R.theta/2)-im*sin(R.theta/2), 0, 0, cos(R.theta/2)+im*sin(R.theta/2))

function apply!(r::ArrayReg, rb::RotationGate)
    v0 = copy(r.state)
    apply!(r, rb.block)
    r.state = -im*sin(rb.theta/2)*r.state + cos(rb.theta/2)*v0
    return r
end

# parametric interface
niparameters(::Type{<:RotationGate}) = 1
iparameters(x::RotationGate) = x.theta
setiparameters!(r::RotationGate, param::Real) = (r.theta = param; r)

YaoBase.isunitary(r::RotationGate) = true

Base.adjoint(blk::RotationGate) = RotationGate(blk.block, -blk.theta)
Base.copy(R::RotationGate) = RotationGate(R.block, R.theta)
Base.:(==)(lhs::RotationGate{TA, GTA}, rhs::RotationGate{TB, GTB}) where {TA, TB, GTA, GTB} = false
Base.:(==)(lhs::RotationGate{TA, GT}, rhs::RotationGate{TB, GT}) where {TA, TB, GT} = lhs.theta == rhs.theta

cache_key(R::RotationGate) = R.theta
