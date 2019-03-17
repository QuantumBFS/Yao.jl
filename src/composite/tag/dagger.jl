export Daggered

"""
    Daggered{N, T, BT} <: TagBlock{N, T}

Wrapper block allowing to execute the inverse of a block of quantum circuit.
"""
struct Daggered{N, T, BT <: AbstractBlock} <: TagBlock{N, T}
    block::BT
end

Daggered(x::BT) where {N, T, BT<:MatrixBlock{N, T}} =
    Daggered{BT, N, T}(x)

PreserveStyle(::Daggered) = PreserveAll()
mat(blk::Daggered) = adjoint(mat(blk.block))

Base.parent(x::Daggered) = x.block
Base.adjoint(x::MatrixBlock) = ishermitian(x) ? x : Daggered(x)
Base.adjoint(x::Daggered) = x.block
Base.similar(c::Daggered, level::Int) = Daggered(similar(c.block))
Base.copy(c::Daggered, level::Int) = Daggered(copy(c.block))
