export ChainBlock, chain

"""
    ChainBlock{D} <: CompositeBlock{D}

`ChainBlock` is a basic construct tool to create
user defined blocks horizontically. It is a `Vector`
like composite type.
"""
struct ChainBlock{D} <: CompositeBlock{D}
    n::Int
    blocks::Vector{AbstractBlock{D}}
    function ChainBlock(n::Int, blocks::Vector{<:AbstractBlock{D}}) where {D}
        _check_block_sizes(blocks, n)
        return new{D}(n, blocks)
    end
end

ChainBlock(blocks::Vector{<:AbstractBlock{D}}) where {D} = ChainBlock(_check_block_sizes(blocks), blocks)
ChainBlock(blocks::AbstractBlock{D}...) where {D} =
    ChainBlock(collect(AbstractBlock{D}, blocks))

nqudits(c::ChainBlock) = c.n

"""
    chain(blocks...)

Return a [`ChainBlock`](@ref) which chains a list of blocks with same
[`nqudits`](@ref). If there is lazy evaluated
block in `blocks`, chain can infer the number of qudits and create an
instance itself.

### Examples

```jldoctest; setup=:(using Yao)
julia> chain(X, Y, Z)
nqubits: 1
chain
├─ X
├─ Y
└─ Z

julia> chain(2, put(1=>X), put(2=>Y), cnot(2, 1))
nqubits: 2
chain
├─ put on (1)
│  └─ X
├─ put on (2)
│  └─ Y
└─ control(2)
   └─ (1,) X
```
"""
chain(blocks::AbstractBlock{D}...) where {D} = ChainBlock(blocks...)
function chain(blocks::Union{AbstractBlock{D},Function}...) where {D}
    blocks = filter(x->x isa AbstractBlock, blocks)
    return chain(map(x -> parse_block(_check_block_sizes(blocks...), x), blocks)...)
end

function chain(list::Vector{<:AbstractVector{D}}) where D
    return ChainBlock(list)
end

# if not all matrix block, try to put the number of qudits.
chain(n::Int, blocks...) = chain(map(x -> parse_block(n, x), blocks)...)
chain(n::Int, itr) = isempty(itr) ? chain(n) : chain(map(x -> parse_block(n, x), itr)...)
# disambiguity
# NOTE: we use parse_block here to make sure the behaviour are the same
chain(n::Int, it::Pair) = chain(n, parse_block(n, it))
chain(n::Int, f::Function) = chain(n, parse_block(n, f))
function chain(n::Int, block::AbstractBlock{D}) where D
    if n != nqudits(block)
        throw(QubitMismatchError("number of qudits mismatch: expect $n, got $(nqudits(block))"))
    end
    return ChainBlock(n, AbstractBlock{D}[block])
end
chain(blocks::Function...) = @λ(n -> chain(n, blocks...))
chain(it) = chain(it...) # forward iterator to vargs, so we could dispatch based on types
chain(it::Pair) = error("got $it, do you mean put($it)?")
chain(blocks...) = @λ(n -> chain(n, blocks))

"""
    chain(n)

Return an empty [`ChainBlock`](@ref) which can be used like a list of blocks.

### Examples

```jldoctest; setup=:(using Yao)
julia> chain(2)
nqubits: 2
chain


julia> chain(2; nlevel=3)
nqudits: 2
chain


```
"""
chain(n::Int; nlevel=2) = ChainBlock(n::Int, AbstractBlock{nlevel}[])

"""
    chain()

Return an lambda `n->chain(n)`.
"""
chain() = @λ(n -> chain(n))

subblocks(c::ChainBlock) = c.blocks
occupied_locs(c::ChainBlock) =
    Tuple(unique(Iterators.flatten(occupied_locs(b) for b in subblocks(c))))

chsubblocks(pb::ChainBlock{D}, blocks::Vector{<:AbstractBlock{D}}) where {D} =
    length(blocks) == 0 ? ChainBlock(pb.n, AbstractBlock{D}[]) : ChainBlock(pb.n, blocks)
chsubblocks(pb::ChainBlock, it) = chain(it...)

function mat(::Type{T}, c::ChainBlock{D}) where {T,D}
    if isempty(c.blocks)
        return IMatrix{D^nqudits(c),T}()
    else
        return prod(x -> mat(T, x), Iterators.reverse(c.blocks))
    end
end

function YaoAPI.unsafe_apply!(r::AbstractRegister, c::ChainBlock)
    for each in c.blocks
        YaoAPI.unsafe_apply!(r, each)
    end
    return r
end

cache_key(c::ChainBlock) = Tuple(cache_key(each) for each in c.blocks)

function Base.:(==)(lhs::ChainBlock{D}, rhs::ChainBlock{D}) where {D}
    nqudits(lhs) == nqudits(rhs) &&
    (length(lhs.blocks) == length(rhs.blocks)) &&
    all(lhs.blocks .== rhs.blocks)
end

Base.copy(c::ChainBlock{D}) where {D} = ChainBlock(c.n, copy(c.blocks))
Base.similar(c::ChainBlock{D}) where {D} = ChainBlock(c.n, empty!(similar(c.blocks)))
Base.getindex(c::ChainBlock, index) = getindex(c.blocks, index)
Base.getindex(c::ChainBlock, index::Union{UnitRange,Vector}) =
    ChainBlock(c.n, getindex(c.blocks, index))
Base.setindex!(c::ChainBlock{D}, val::AbstractBlock{D}, index::Integer) where {D} =
    (_check_block_sizes(c, val); setindex!(c.blocks, val, index); c)
Base.insert!(c::ChainBlock{D}, index::Integer, val::AbstractBlock{D}) where {D} =
    (_check_block_sizes(c, val); insert!(c.blocks, index, val); c)
Base.adjoint(blk::ChainBlock{D}) where {D} =
    ChainBlock(blk.n, AbstractBlock{D}[adjoint(b) for b in reverse(subblocks(blk))])
Base.lastindex(c::ChainBlock) = lastindex(c.blocks)
## Iterate contained blocks
Base.iterate(c::ChainBlock, st = 1) = iterate(c.blocks, st)
Base.length(c::ChainBlock) = length(c.blocks)
Base.eltype(c::ChainBlock) = eltype(c.blocks)
Base.eachindex(c::ChainBlock) = eachindex(c.blocks)
Base.popfirst!(c::ChainBlock) = popfirst!(c.blocks)
Base.pop!(c::ChainBlock) = pop!(c.blocks)
Base.push!(c::ChainBlock{D}, m::AbstractBlock{D}) where {D} = (_check_block_sizes(c, m); push!(c.blocks, m); c)
Base.push!(c::ChainBlock{D}, f::Function) where {D} = (push!(c.blocks, f(c.n)); c)
Base.pushfirst!(c::ChainBlock{D}, m::AbstractBlock{D}) where {D} =
    (_check_block_sizes(c, m); pushfirst!(c.blocks, m); c)
Base.pushfirst!(c::ChainBlock{D}, f::Function) where {D} = (pushfirst!(c.blocks, f(c.n)); c)
Base.append!(c::ChainBlock{D}, list::Vector{<:AbstractBlock{D}}) where {D} =
    (_check_block_sizes(c, list...); append!(c.blocks, list); c)
Base.append!(c1::ChainBlock{D}, c2::ChainBlock{D}) where {D} =
    (_check_block_sizes(c1, c2); append!(c1.blocks, c2.blocks); c1)
Base.prepend!(c1::ChainBlock{D}, list::Vector{<:AbstractBlock{D}}) where {D} =
    (_check_block_sizes(c1, list...); prepend!(c1.blocks, list); c1)
Base.prepend!(c1::ChainBlock{D}, c2::ChainBlock{D}) where {D} =
    (_check_block_sizes(c1, c2); prepend!(c1.blocks, c2.blocks); c1)

YaoAPI.isunitary(c::ChainBlock) = all(isunitary, c.blocks) || isunitary(mat(c))
YaoAPI.isreflexive(c::ChainBlock) =
    (iscommute(c.blocks...) && all(isreflexive, c.blocks)) || isreflexive(mat(c))
LinearAlgebra.ishermitian(c::ChainBlock) =
    (all(isreflexive, c.blocks) && iscommute(c.blocks...)) || isreflexive(mat(c))

# this is not type stable, possible to fix?
function unsafe_getindex(::Type{T}, c::ChainBlock{D}, i::Integer, j::Integer) where {D,T}
    if length(c) == 0
        return i==j ? one(T) : zero(T)
    elseif length(c) == 1
        return unsafe_getindex(T, c.blocks[1], i, j)
    else
        table = propagate_chain(c.blocks[2:end-1], c.blocks[1][:, DitStr{D,nqudits(c)}(j)])
        res = zero(T)
        for (loc, amp) in table
            res += unsafe_getindex(T, c.blocks[end], i, buffer(loc)) * amp
        end
        return res
    end
end

function unsafe_getcol(::Type{T}, c::ChainBlock{D}, j::DitStr{D,N,TI}) where {D,N,TI,T}
    if length(c) == 0
        return [j], [one(T)]
    elseif length(c) == 1
        return unsafe_getcol(T, c.blocks[1], j)
    else
        table = propagate_chain(c.blocks[2:end], c.blocks[1][:,j])
        return table.configs, table.amplitudes
    end
end
# propagate the configurations along the chain
function propagate_chain(blocks, i::EntryTable; cleanup_threshold=Inf)
    for b in blocks
        i = b[:,i]
        if length(i) >= cleanup_threshold
            i = cleanup(i)
        end
    end
    return i
end
function Base.getindex(b::ChainBlock{D}, i::DitStr{D,N}, j::DitStr{D,N}) where {D,N}
    invoke(Base.getindex, Tuple{AbstractBlock{D}, DitStr{D,N}, DitStr{D,N}} where {D,N}, b, i, j)
end
function Base.getindex(b::ChainBlock{D}, ::Colon, j::DitStr{D,N}) where {D,N}
    T = promote_type(ComplexF64, parameters_eltype(b))
    return _getindex(T, b, :, j)
end
function Base.getindex(b::ChainBlock{D}, i::DitStr{D,N}, ::Colon) where {D,N}
    T = promote_type(ComplexF64, parameters_eltype(b))
    return _getindex(T, b, i, :)
end
function Base.getindex(b::ChainBlock{D}, ::Colon, j::EntryTable{DitStr{D,N,TI},T}) where {D,N,TI,T}
    return _getindex(b, :, j)
end
function Base.getindex(b::ChainBlock{D}, i::EntryTable{DitStr{D,N,TI},T}, ::Colon) where {D,N,TI,T}
    return _getindex(b, i, :)
end