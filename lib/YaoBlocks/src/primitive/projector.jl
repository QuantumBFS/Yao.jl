export Projector, projector

"""
    struct Projector{D, T, AT<:(AbstractArrayReg{D, T})} <: PrimitiveBlock{D}

Projection operator to target state `psi`.

### Definition
`projector(s)` defines the following operator.

```math
|s⟩ → |s⟩⟨s|
```
"""
struct Projector{D, T, AT<:AbstractArrayReg{D, T}} <: PrimitiveBlock{D}
    psi::AT
    function Projector(psi::AbstractArrayReg{D, T}) where {D,T}
        @assert isnormalized(psi) && nremain(psi) == 0 "the state in the projector must be normalized and does not contain environment."
        new{D,T,typeof(psi)}(psi)
    end
end
nqudits(v::Projector) = nqudits(v.psi)
print_block(io::IO, p::Projector) = print(io, "|s⟩⟨s|, nqudits = $(nqudits(p))")

"""
    project(x::AbstractArrayReg) -> Projector

Create a [`Projector`](@ref) with an quantum state vector `v`.

### Example

```jldoctest; setup=:(using YaoBlocks, YaoArrayRegister)
julia> projector(rand_state(3))
|s⟩⟨s|, nqudits = 3
```
"""
projector(v::AbstractArrayReg)::Projector = Projector(v)

function YaoAPI.unsafe_apply!(r::AbstractArrayReg, g::Projector{D, T}) where {D, T}
    v = state(g.psi)
    r.state .= v' * r.state .* v
    return r
end

# target type is the same with block's
function mat(::Type{T1}, r::Projector{D, T2}) where {D, T1, T2}
    v = state(r.psi)
    if T1 != T2
        v = copyto!(similar(v, T1), v)
    end
    return OuterProduct(v, conj.(v))
end

Base.:(==)(A::Projector, B::Projector) = A.psi == B.psi
Base.copy(r::Projector) = Projector(copy(r.psi))

LinearAlgebra.ishermitian(::Projector) = true
YaoAPI.isdiagonal(::Projector) = false
#YaoAPI.isreflexive(r::Projector) = false
#YaoAPI.isunitary(r::Projector) = false
