using YaoBase, YaoArrayRegister

export ReflectGate, reflect

"""
    ReflectGate{N, T, Tr} <: PrimitiveBlock{N, T}

Reflection operator to target state `psi`.

# Definition

```math
|ψ⟩ → 2 |s⟩⟨s| - 1
```
"""
struct ReflectGate{N, T, Tr <: AbstractRegister{1, T}} <: PrimitiveBlock{N, T}
    psi::Tr
end

"""
    ReflectGate(r::ArrayReg{1})

Create a [`ReflectGate`](@ref) with a quantum register `r`.
"""
ReflectGate(r::ArrayReg{1, T}) where T = ReflectGate{nqubits(r), T, typeof(r)}(r)

"""
    ReflectGate(r::AbstractVector)

Create a [`ReflectGate`](@ref) with a quantum state vector `v`.
"""
ReflectGate(v::AbstractVector{<:Complex}) = ReflectGate(ArrayReg(v))

"""
    reflect(r::ArrayReg)

Create a [`ReflectGate`](@ref) with an [`ArrayReg`](@ref).
"""
reflect(r::ArrayReg) = reflect(statevec(r))

"""
    reflect(v::AbstractVector{<:Complex})

Create a [`ReflectGate`](@ref) with an quantum state vector `v`.

# Example

```jldoctest
julia> reflect(rand_state(3))
reflect(ArrayReg{1, Complex{Float64}, Array...})
```
"""
reflect(v::AbstractVector{<:Complex}) = ReflectGate(v)

function apply!(r::ArrayReg, g::ReflectGate{N, T, <:ArrayReg}) where {N, T}
    v = state(g.psi)
    r.state .= 2 .* (v' * r.state) .* v - r.state
    return r
end

function mat(r::ReflectGate)
    v = statevec(r.psi)
    return 2 * v * v' - IMatrix(length(v))
end

Base.:(==)(A::ReflectGate, B::ReflectGate) = A.psi == B.psi
Base.copy(r::ReflectGate) = ReflectGate(r.psi)

YaoBase.isreflexive(::ReflectGate) = true
YaoBase.ishermitian(::ReflectGate) = true
YaoBase.isunitary(::ReflectGate) = true
