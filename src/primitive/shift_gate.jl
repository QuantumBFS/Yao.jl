using YaoBase

export ShiftGate, shift

"""
    ShiftGate <: PrimitiveBlock

Phase shift gate.

# Definition

```math
\\begin{pmatrix}
1 & 0\\
0 & e^(im θ)
\\end{pmatrix}
```
"""
mutable struct ShiftGate{T <: Real} <: PrimitiveBlock{1}
    theta::T
end

"""
    shift(θ)

Create a [`ShiftGate`](@ref) with phase `θ`.

# Example

```jldoctest
julia> shift(0.1)
shift(0.1)
```
"""
shift(θ::AbstractFloat) = ShiftGate(θ)
shift(θ::Real) = shift(Float64(θ))
mat(::Type{T}, gate::ShiftGate) where {T <: Complex} = Diagonal(T[1.0, exp(im * gate.theta)])

cache_key(gate::ShiftGate) = gate.theta

# parametric interface
niparams(::Type{<:ShiftGate}) = 1
getiparams(x::ShiftGate) = x.theta
setiparams!(r::ShiftGate, param::Real) = (r.theta = param; r)


Base.adjoint(blk::ShiftGate) = ShiftGate(-blk.theta)
Base.copy(block::ShiftGate{T}) where T = ShiftGate{T}(block.theta)
Base.:(==)(lhs::ShiftGate, rhs::ShiftGate) = lhs.theta == rhs.theta
YaoBase.isunitary(r::ShiftGate) = true
