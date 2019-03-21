export Daggered

"""
    Daggered{N, T, BT} <: TagBlock{N, T}

Wrapper block allowing to execute the inverse of a block of quantum circuit.
"""
struct Daggered{N, T, BT <: AbstractBlock} <: TagBlock{N, T, BT}
    content::BT
end

Daggered(x::BT) where {N, T, BT<:AbstractBlock{N, T}} =
    Daggered{BT, N, T}(x)

PreserveStyle(::Daggered) = PreserveAll()
mat(blk::Daggered) = adjoint(mat(content(blk)))

Base.adjoint(x::AbstractBlock) = ishermitian(x) ? x : Daggered(x)
Base.adjoint(x::Daggered) = content(x)
Base.copy(x::Daggered) = Daggered(copy(content(x)))
