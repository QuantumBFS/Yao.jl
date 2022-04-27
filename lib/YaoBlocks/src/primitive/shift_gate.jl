export ShiftGate, shift

"""
    ShiftGate <: PrimitiveBlock

Phase shift gate.
"""
mutable struct ShiftGate{T} <: PrimitiveBlock{2}
    theta::T
end

ShiftGate(theta::Integer) = ShiftGate(Float64(theta))
nqudits(blk::ShiftGate) = 1

"""
    shift(θ)

Create a [`ShiftGate`](@ref) with phase `θ`.

```math
\\begin{pmatrix}
1 & 0\\\\
0 & \\exp^{iθ}
\\end{pmatrix}
```

### Examples

```jldoctest; setup=:(using YaoBlocks)
julia> shift(0.1)
shift(0.1)
```
"""
shift(θ) = ShiftGate(θ)
mat(::Type{T}, gate::ShiftGate) where {T} = Diagonal(T[1.0, exp(im * gate.theta)])

cache_key(gate::ShiftGate) = gate.theta

# parametric interface
niparams(::Type{<:ShiftGate}) = 1
getiparams(x::ShiftGate) = x.theta
setiparams!(r::ShiftGate, param::Number) = (r.theta = param; r)
setiparams(r::ShiftGate, param::Number) = ShiftGate(param)


Base.adjoint(blk::ShiftGate) = ShiftGate(-blk.theta)
Base.copy(block::ShiftGate{T}) where {T} = ShiftGate{T}(block.theta)
Base.:(==)(lhs::ShiftGate, rhs::ShiftGate) = lhs.theta == rhs.theta

# fallback to matrix method if it is not real
YaoAPI.isunitary(r::ShiftGate{<:Real}) = true

function YaoAPI.isunitary(r::ShiftGate)
    isreal(r.theta) && return true
    @warn "θ in ShiftGate is not real, got θ=$(r.theta), fallback to matrix-based method"
    return isunitary(mat(r))
end

iparams_range(::ShiftGate{T}) where {T} = ((zero(T), T(2.0 * pi)),)
