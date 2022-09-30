export ReflectGate, reflect

ReflectGate{D, T, Tt, AT<:AbstractArrayReg{D, T}} = TimeEvolution{D,Tt,Projector{D,T,AT}}

"""
    reflect(v::AbstractArrayReg) -> ReflectGate{D,T} where {D,T}
    reflect(v::AbstractArrayReg, θ::Real) -> ReflectGate{D,T} where {D,T}

Create a [`ReflectGate`](@ref) with respect to an quantum state vector `v`.
It defines the following gate operation.

```math
|v⟩ → 1 - (1-exp(-iθ)) |v⟩⟨v|
```

When ``θ = π``, it defines a standard reflection gate ``1-2|v⟩⟨v|``.

### Example

```jldoctest; setup=:(using YaoBlocks, YaoArrayRegister)
julia> reflect(rand_state(3))
Time Evolution Δt = π, tol = 1.0e-7
|s⟩⟨s|, nqudits = 3
```
"""
reflect(v::AbstractArrayReg, θ::Real=π)::ReflectGate = time_evolve(Projector(v), θ)

function YaoAPI.unsafe_apply!(r::AbstractArrayReg, g::ReflectGate)
    v = state(g.H.psi)
    r.state .= r.state .- (1-exp(-im*g.dt)) .* (v * (v' * r.state))
    return r
end

# target type is the same with block's
function mat(::Type{T1}, r::ReflectGate{D, T2}) where {D, T1, T2}
    v = state(r.H.psi)
    return T1.(IMatrix(size(v, 1)) .- (1-exp(-im*r.dt)) .* mat(T1, r.H))
end

LinearAlgebra.ishermitian(r::ReflectGate) = r.dt ≈ π
YaoAPI.isreflexive(r::ReflectGate) = r.dt ≈ π
