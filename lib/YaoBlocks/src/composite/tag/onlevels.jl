export OnLevels

"""
    OnLevels{D, Ds, T <: AbstractBlock{Ds}} <: TagBlock{T, D}

Define a gate that is applied to a subset of levels.

### Fields
- `gate`: the gate to be applied.
- `levels`: the levels to apply the gate to.
"""
struct OnLevels{D, Ds, T <: AbstractBlock{Ds}} <: TagBlock{T, D}
    gate::T
    levels::NTuple{Ds, Int}
    function OnLevels{D}(gate::T, levels::NTuple{Ds, Int}) where {D, Ds, T <: AbstractBlock{Ds}}
        @assert nqudits(gate) == 1 "only single qubit gate is supported"
        new{D, Ds, T}(gate, levels)
    end
end
content(g::OnLevels) = g.gate
function mat(::Type{T}, g::OnLevels{D, Ds}) where {T, D, Ds}
    m = mat(T, g.gate)
    iter = IterNz(m)
    nnz = length(iter)
    is, js, vs = Vector{Int}(undef, nnz), Vector{Int}(undef, nnz), Vector{T}(undef, nnz)
    for (k, (i, j, v)) in enumerate(iter)
        is[k] = g.levels[i]
        js[k] = g.levels[j]
        vs[k] = v
    end
    return sparse(is, js, vs, D, D)
end
PropertyTrait(::OnLevels) = PreserveAll()
Base.adjoint(x::OnLevels{D}) where D = OnLevels{D}(adjoint(x.gate), x.levels)
Base.copy(x::OnLevels{D}) where D = OnLevels{D}(copy(x.gate), x.levels)