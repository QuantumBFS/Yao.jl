export Sequence
import YaoBlocks: subblocks, chsubblocks, apply!
using YaoBlocks: _check_size

struct Sequence <: CompositeBlock{Any}
    blocks::Vector
end

Sequence(args...) = Sequence(collect(AbstractBlock, args))

subblocks(seq::Sequence) = filter(x->x isa AbstractBlock, seq.blocks)
chsubblocks(pb::Sequence, blocks::Vector) = Sequence(blocks)

function apply!(reg::ArrayReg, seq::Sequence)
    for x in seq.blocks
        reg |> x
    end
    reg
end

for PROP in [:lastindex, :firstindex, :getindex, :length, :eltype, :iterate, :eachindex, :popfirst!, :pop!]
    @eval Base.$PROP(c::Sequence, args...; kwargs...) = $PROP(c.blocks, args...; kwargs...)
end

function Base.:(==)(lhs::Sequence, rhs::Sequence)
    (length(lhs.blocks) == length(rhs.blocks)) && all(lhs.blocks .== rhs.blocks)
end

Base.copy(c::Sequence) = Sequence(copy(c.blocks))
Base.similar(c::Sequence) = Sequence(empty!(similar(c.blocks)))
Base.getindex(c::Sequence, index::Union{UnitRange, Vector}) = Sequence(getindex(c.blocks, index))

Base.setindex!(c::Sequence, val::AbstractBlock{N}, index::Integer) where N = (setindex!(c.blocks, val, index); c)
Base.insert!(c::Sequence, index::Integer, val::AbstractBlock{N}) where N = (insert!(c.blocks, index, val); c)
Base.push!(c::Sequence, m) where N = (push!(c.blocks, m); c)
Base.append!(c::Sequence, list::Vector) where N = (append!(c.blocks, list); c)
Base.append!(c1::Sequence, c2::Sequence) where N = (append!(c1.blocks, c2.blocks); c1)
Base.prepend!(c1::Sequence, list::Vector{<:AbstractBlock{N}}) where N = (prepend!(c1.blocks, list); c1)
Base.prepend!(c1::Sequence, c2::Sequence) where N = (prepend!(c1.blocks, c2.blocks); c1)
