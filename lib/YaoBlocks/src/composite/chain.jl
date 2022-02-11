using YaoBase

export ChainBlock, chain

"""
    ChainBlock{N,D} <: CompositeBlock{N,D}

`ChainBlock` is a basic construct tool to create
user defined blocks horizontically. It is a `Vector`
like composite type.
"""
struct ChainBlock{N,D} <: CompositeBlock{N,D}
    blocks::Vector{AbstractBlock{N,D}}
end

ChainBlock{N}(blocks; nlevel=2) where N = ChainBlock{N,nlevel}(blocks)
ChainBlock(blocks::Vector{<:AbstractBlock{N,D}}) where {N,D} = ChainBlock{N,D}(blocks)
ChainBlock(blocks::AbstractBlock{N,D}...) where {N,D} =
    ChainBlock(collect(AbstractBlock{N,D}, blocks))

"""
    chain(blocks...)

Return a [`ChainBlock`](@ref) which chains a list of blocks with same
[`nqubits`](@ref). If there is lazy evaluated
block in `blocks`, chain can infer the number of qubits and create an
instance itself.
"""
chain(blocks::AbstractBlock{N,D}...) where {N,D} = ChainBlock(blocks...)
chain(blocks::Union{AbstractBlock{N,D},Function}...) where {N,D} =
    chain(map(x -> parse_block(N, x), blocks)...)

function chain(list::Vector)
    for each in list # check type
        each isa AbstractBlock || error("expect a block, got $(typeof(each))")
    end
    N = nqubits(first(list))
    D = nlevel(first(list))
    return ChainBlock(Vector{AbstractBlock{N,D}}(list))
end

# if not all matrix block, try to put the number of qubits.
chain(n::Int, blocks...) = chain(map(x -> parse_block(n, x), blocks)...)
chain(n::Int, itr) = isempty(itr) ? chain(n) : chain(map(x -> parse_block(n, x), itr)...)
# disambiguity
# NOTE: we use parse_block here to make sure the behaviour are the same
chain(n::Int, it::Pair) = chain(n, parse_block(n, it))
chain(n::Int, f::Function) = chain(n, parse_block(n, f))
function chain(n::Int, block::AbstractBlock)
    @assert n == nqubits(block) "number of qubits mismatch"
    return ChainBlock(block)
end
chain(blocks::Function...) = @λ(n -> chain(n, blocks...))
chain(it) = chain(it...) # forward iterator to vargs, so we could dispatch based on types
chain(it::Pair) = error("got $it, do you mean put($it)?")
chain(blocks...) = @λ(n -> chain(n, blocks))

"""
    chain(n)

Return an empty [`ChainBlock`](@ref) which can be used like a list of blocks.
"""
chain(n::Int) = ChainBlock{n}(AbstractBlock{n}[])

"""
    chain()

Return an lambda `n->chain(n)`.
"""
chain() = @λ(n -> chain(n))

subblocks(c::ChainBlock) = c.blocks
occupied_locs(c::ChainBlock) =
    Tuple(unique(Iterators.flatten(occupied_locs(b) for b in subblocks(c))))

chsubblocks(pb::ChainBlock{N,D}, blocks::Vector{<:AbstractBlock}) where {N,D} =
    length(blocks) == 0 ? ChainBlock{N,D}([]) : ChainBlock(blocks)
chsubblocks(pb::ChainBlock, it) = chain(it...)

function mat(::Type{T}, c::ChainBlock) where {T}
    if isempty(c.blocks)
        return IMatrix{1 << nqubits(c),T}()
    else
        return prod(x -> mat(T, x), Iterators.reverse(c.blocks))
    end
end

function _apply!(r::AbstractRegister, c::ChainBlock)
    for each in c.blocks
        _apply!(r, each)
    end
    return r
end

cache_key(c::ChainBlock) = Tuple(cache_key(each) for each in c.blocks)

function Base.:(==)(lhs::ChainBlock{N,D}, rhs::ChainBlock{N,D}) where {N,D}
    (length(lhs.blocks) == length(rhs.blocks)) && all(lhs.blocks .== rhs.blocks)
end

Base.copy(c::ChainBlock{N,D}) where {N,D} = ChainBlock{N,D}(copy(c.blocks))
Base.similar(c::ChainBlock{N,D}) where {N,D} = ChainBlock{N,D}(empty!(similar(c.blocks)))
Base.getindex(c::ChainBlock, index) = getindex(c.blocks, index)
Base.getindex(c::ChainBlock, index::Union{UnitRange,Vector}) =
    ChainBlock(getindex(c.blocks, index))
Base.setindex!(c::ChainBlock{N,D}, val::AbstractBlock{N,D}, index::Integer) where {N,D} =
    (setindex!(c.blocks, val, index); c)
Base.insert!(c::ChainBlock{N,D}, index::Integer, val::AbstractBlock{N,D}) where {N,D} =
    (insert!(c.blocks, index, val); c)
Base.adjoint(blk::ChainBlock{N,D}) where {N,D} =
    ChainBlock{N,D}(map(adjoint, reverse(subblocks(blk))))
Base.lastindex(c::ChainBlock) = lastindex(c.blocks)
## Iterate contained blocks
Base.iterate(c::ChainBlock, st = 1) = iterate(c.blocks, st)
Base.length(c::ChainBlock) = length(c.blocks)
Base.eltype(c::ChainBlock) = eltype(c.blocks)
Base.eachindex(c::ChainBlock) = eachindex(c.blocks)
Base.popfirst!(c::ChainBlock) = popfirst!(c.blocks)
Base.pop!(c::ChainBlock) = pop!(c.blocks)
Base.push!(c::ChainBlock{N,D}, m::AbstractBlock{N,D}) where {N,D} = (push!(c.blocks, m); c)
Base.push!(c::ChainBlock{N,D}, f::Function) where {N,D} = (push!(c.blocks, f(N)); c)
Base.pushfirst!(c::ChainBlock{N,D}, m::AbstractBlock{N,D}) where {N,D} =
    (pushfirst!(c.blocks, m); c)
Base.pushfirst!(c::ChainBlock{N,D}, f::Function) where {N,D} = (pushfirst!(c.blocks, f(N)); c)
Base.append!(c::ChainBlock{N,D}, list::Vector{<:AbstractBlock{N,D}}) where {N,D} =
    (append!(c.blocks, list); c)
Base.append!(c1::ChainBlock{N,D}, c2::ChainBlock{N,D}) where {N,D} =
    (append!(c1.blocks, c2.blocks); c1)
Base.prepend!(c1::ChainBlock{N,D}, list::Vector{<:AbstractBlock{N,D}}) where {N,D} =
    (prepend!(c1.blocks, list); c1)
Base.prepend!(c1::ChainBlock{N,D}, c2::ChainBlock{N,D}) where {N,D} =
    (prepend!(c1.blocks, c2.blocks); c1)

YaoBase.isunitary(c::ChainBlock) = all(isunitary, c.blocks) || isunitary(mat(c))
YaoBase.isreflexive(c::ChainBlock) =
    (iscommute(c.blocks...) && all(isreflexive, c.blocks)) || isreflexive(mat(c))
YaoBase.ishermitian(c::ChainBlock) =
    (all(isreflexive, c.blocks) && iscommute(c.blocks...)) || isreflexive(mat(c))
