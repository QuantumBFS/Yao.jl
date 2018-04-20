abstract type AbstractBlock{N} <: AbstractGate{N} end

struct Concentrator <: AbstractBlock{N}
end

struct Block{N} <: AbstractBlock{N}
    index::Vector
    gates::Vector
end

apply!(block::AbstractBlock, pos::NTuple{N, Int}, gate) where N = 0
apply!(block::AbstractBlock, pos::Tuple{}, gate) = 0
