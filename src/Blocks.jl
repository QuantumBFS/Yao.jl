abstract type AbstractBlock{N} end

function apply(block::AbstractBlock{N}, reg::AbstractRegister{N}) where N end

abstract type LeafBlock{N} <: AbstractBlock{N} end

struct ChainBlock{N} <: AbstractBlock{N}
    list::Vector
end

struct KronBlock{N} <: AbstractBlock{N}
    heads::Vector{Int}
    list::Vector
end

struct Concentrator{N, M, T <: AbstractBlock{M}} <: AbstractBlock{N}
    concentrated_ids::NTuple{M, Int}
    block::T
end

struct GateBlock{N, GT} <: LeafBlock{N}
end
