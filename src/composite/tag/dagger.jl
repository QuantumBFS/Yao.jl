export Dag

"""
    Dag{N, T, BT} <: TagBlock{N, T}

Wrapper block allowing to execute the inverse of a block of quantum circuit.
"""
struct Dag{N, T, BT <: AbstractBlock} <: TagBlock{N, T}
    block::BT
end

Dag(x::BT) where {N, T, BT<:AbstractBlock{N, T}} =
    Dag{BT, N, T}(x)

PreserveStyle(::Dag) = PreserveAll()
mat(blk::Dag) = adjoint(mat(blk.block))

Base.adjoint(x::AbstractBlock) = ishermitian(x) ? x : Dag(x)
Base.adjoint(x::Dag) = x.block
Base.similar(c::Dag, level::Int) = Dag(similar(c.block))
Base.copy(c::Dag, level::Int) = Dag(copy(c.block))
