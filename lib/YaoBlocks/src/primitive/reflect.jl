export ReflectGate, reflect

"""
$(TYPEDEF)

Reflection operator to target state `psi`.

### Definition
`reflect(s)` defines the following gate operation.

```math
|s⟩ → 2 |s⟩⟨s| - 1
```
"""
struct ReflectGate{D, T, AT<:AbstractArrayReg{D, T}} <: PrimitiveBlock{D}
    psi::AT
    function ReflectGate(psi::AbstractArrayReg{D, T}) where {D,T}
        @assert isnormalized(psi) && nremain(psi) == 0 "the state in the projector must be normalized and does not contain environment."
        new{D,T,typeof(psi)}(psi)
    end
end
nqudits(v::ReflectGate) = nqudits(v.psi)

"""
$(TYPEDSIGNATURES)

Create a [`ReflectGate`](@ref) with an quantum state vector `v`.

### Example

```jldoctest; setup=:(using YaoBlocks)
julia> reflect(rand_state(3))
reflect(ArrayReg{1, Complex{Float64}, Array...})
```
"""
reflect(v::AbstractArrayReg)::ReflectGate = ReflectGate(v)

function unsafe_apply!(r::AbstractArrayReg, g::ReflectGate{D, T, <:AbstractArrayReg}) where {D, T}
    v = state(g.psi)
    r.state .= 2 .* (v' * r.state) .* v - r.state
    return r
end

# target type is the same with block's
function mat(::Type{T}, r::ReflectGate{D, T}) where {D, T}
    v = state(r.psi)
    return 2 * v * v' - IMatrix(size(v, 1))
end

# different
function mat(::Type{T1}, r::ReflectGate{D, T2}) where {D, T1, T2}
    M = mat(T2, r)
    return copyto!(similar(M, T1), M)
end

Base.:(==)(A::ReflectGate, B::ReflectGate) = A.psi == B.psi
Base.copy(r::ReflectGate) = ReflectGate(copy(r.psi))

LinearAlgebra.ishermitian(::ReflectGate) = true
YaoAPI.isreflexive(r::ReflectGate) = true
YaoAPI.isdiagonal(::ReflectGate) = false
YaoAPI.isunitary(r::ReflectGate) = true
