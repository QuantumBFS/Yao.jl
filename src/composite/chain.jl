using YaoBase

export ChainBlock, chain

"""
    ChainBlock{N, T} <: CompositeBlock{N, T}

`ChainBlock` is a basic construct tool to create
user defined blocks horizontically. It is a `Vector`
like composite type.
"""
struct ChainBlock{N, T, MT <: AbstractBlock{N, T}} <: CompositeBlock{N, T}
    blocks::Vector{MT}
end

ChainBlock(blocks::AbstractBlock{N, T}...) where {N, T} = ChainBlock(collect(AbstractBlock{N, T}, blocks))
ChainBlock(c::ChainBlock{N, T, MT}) where {N, T, MT} = copy(c)

"""
    chain(blocks...)

Return a [`ChainBlock`](@ref) which chains a list of blocks with same
[`nqubits`](@ref) and [`datatype`](@ref). If there is lazy evaluated
block in `blocks`, chain can infer the number of qubits and create an
instance itself.
"""
chain(blocks::AbstractBlock{N, T}...) where {N, T} = ChainBlock(blocks...)
chain(blocks::Union{AbstractBlock{N, T}, Function}...) where {N, T} = chain(map(x->parse_block(N, x), blocks)...)
chain(list::Vector) = ChainBlock(list)

# if not all matrix block, try to put the number of qubits.
chain(n::Int, blocks...) = chain(map(x->parse_block(n, x), blocks)...)
chain(n::Int, itr) = chain(map(x->parse_block(n, x), itr)...)
chain(blocks::Function...) = @λ(n->chain(n, blocks...))

"""
    chain([T=ComplexF64], n)

Return an empty [`ChainBlock`](@ref) which can be used like a list of blocks.
"""
chain(n::Int) = chain(ComplexF64, n)
chain(::Type{T}, n::Int) = chain(AbstractBlock{n, T}[])

"""
    chain()

Return an lambda `n->chain(n)`.
"""
chain() = @λ(n->chain(n))

subblocks(c::ChainBlock) = c.blocks
occupied_locations(c::ChainBlock) =
    unique(Iterators.flatten(occupied_locations(b) for b in subblocks(c)))
chsubblocks(pb::ChainBlock, blocks) = ChainBlock(blocks)

mat(c::ChainBlock) = prod(x->mat(x), reverse(c.blocks))

function apply!(r::AbstractRegister, c::ChainBlock)
    for each in c.blocks
        apply!(r, each)
    end
    return r
end

cache_key(c::ChainBlock) = [cache_key(each) for each in c.blocks]

function Base.:(==)(lhs::ChainBlock{N, T}, rhs::ChainBlock{N, T}) where {N, T}
    (length(lhs.blocks) == length(rhs.blocks)) && all(lhs.blocks .== rhs.blocks)
end

Base.copy(c::ChainBlock) = ChainBlock{N, T, MT}(copy(c.blocks))
Base.similar(c::ChainBlock{N, T, MT}) where {N, T, MT} = ChainBlock{N, T}(empty!(similar(c.blocks)))
Base.getindex(c::ChainBlock, index) = getindex(c.blocks, index)
Base.getindex(c::ChainBlock, index::Union{UnitRange, Vector}) = ChainBlock(getindex(c.blocks, index))
Base.setindex!(c::ChainBlock{N}, val::AbstractBlock{N}, index::Integer) where N = (setindex!(c.blocks, val, index); c)
Base.insert!(c::ChainBlock{N}, index::Integer, val::AbstractBlock{N}) where N = (insert!(c.blocks, index, val); c)
Base.adjoint(blk::ChainBlock{N, T, MT}) where {N, T, MT} = ChainBlock{N, T, MT}(map(adjoint, reverse(subblocks(blk))))
Base.lastindex(c::ChainBlock) = lastindex(c.blocks)
## Iterate contained blocks
Base.iterate(c::ChainBlock, st=1) = iterate(c.blocks, st)
Base.length(c::ChainBlock) = length(c.blocks)
Base.eltype(c::ChainBlock) = eltype(c.blocks)
Base.eachindex(c::ChainBlock) = eachindex(c.blocks)
Base.popfirst!(c::ChainBlock) = popfirst!(c.blocks)
Base.pop!(c::ChainBlock) = pop!(c.blocks)
Base.push!(c::ChainBlock{N}, m::AbstractBlock{N}) where N = (push!(c.blocks, m); c)
Base.push!(c::ChainBlock{N}, f::Function) where N = (push!(c.blocks, f(N)); c)
Base.append!(c::ChainBlock{N}, list::Vector{<:AbstractBlock{N}}) where N = (append!(c.blocks, list); c)
Base.append!(c1::ChainBlock{N}, c2::ChainBlock{N}) where N = (append!(c1.blocks, c2.blocks); c1)
Base.prepend!(c1::ChainBlock{N}, list::Vector{<:AbstractBlock{N}}) where N = (prepend!(c1.blocks, list); c1)
Base.prepend!(c1::ChainBlock{N}, c2::ChainBlock{N}) where N = (prepend!(c1.blocks, c2.blocks); c1)

YaoBase.isunitary(c::ChainBlock) = all(isunitary, c.blocks) || isunitary(mat(c))
YaoBase.isreflexive(c::ChainBlock) = (iscommute(c.blocks...) && all(isreflexive, c.blocks)) || isreflexive(mat(c))
YaoBase.ishermitian(c::ChainBlock) = (all(isreflexive, c.blocks) && iscommute(c.blocks...)) || isreflexive(mat(c))
