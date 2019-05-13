export Daggered

"""
    Daggered{N, BT} <: TagBlock{N}

Wrapper block allowing to execute the inverse of a block of quantum circuit.
"""
struct Daggered{BT <: AbstractBlock, N} <: TagBlock{BT, N}
    content::BT
end

Daggered(x::BT) where {N, BT<:AbstractBlock{N}} =
    Daggered{BT, N}(x)

PreserveStyle(::Daggered) = PreserveAll()
mat(::Type{T}, blk::Daggered) where T = adjoint(mat(T, content(blk)))

Base.adjoint(x::AbstractBlock) = ishermitian(x) ? x : Daggered(x)
Base.adjoint(x::Daggered) = content(x)
Base.copy(x::Daggered) = Daggered(copy(content(x)))
