export ChainBlock

"""
    ChainBlock{N, T} <: CompositeBlock{N, T}

`ChainBlock` is a basic construct tool to create
user defined blocks horizontically. It is a `Vector`
like composite type.
"""
struct ChainBlock{N, T} <: CompositeBlock{N, T}
    blocks::Vector{MatrixBlock}

    function ChainBlock{N, T}(blocks::Vector) where {N, T}
        new{N, T}(blocks)
    end

    # type promotion
    function ChainBlock(blocks::Vector{<:MatrixBlock{N}}) where N
        T = promote_type(collect(datatype(each) for each in blocks)...)
        new{N, T}(blocks)
    end
end

function ChainBlock(blocks::MatrixBlock{N}...) where N
    ChainBlock(collect(blocks))
end

function Base.copy(c::ChainBlock{N, T}) where {N, T}
    ChainBlock{N, T}(copy(c.blocks))
end

function Base.similar(c::ChainBlock{N, T}) where {N, T}
    ChainBlock{N, T}(empty!(similar(c.blocks)))
end

# Additional Methods for Composite Blocks
Base.getindex(c::ChainBlock, index) = getindex(c.blocks, index)
Base.getindex(c::ChainBlock, index::Union{UnitRange, Vector}) = ChainBlock(getindex(c.blocks, index))
Base.setindex!(c::ChainBlock{N}, val::MatrixBlock{N}, index::Integer) where N = (setindex!(c.blocks, val, index); c)
Base.insert!(c::ChainBlock{N}, index::Integer, val::MatrixBlock{N}) where N = (insert!(c.blocks, index, val); c)
Base.adjoint(blk::ChainBlock) = typeof(blk)(map(adjoint, subblocks(blk) |> reverse))

Base.lastindex(c::ChainBlock) = lastindex(c.blocks)

## Iterate contained blocks
Base.iterate(c::ChainBlock, st=1) = iterate(c.blocks, st)
Base.length(c::ChainBlock) = length(c.blocks)
Base.eltype(c::ChainBlock) = eltype(c.blocks)
Base.eachindex(c::ChainBlock) = eachindex(c.blocks)
subblocks(c::ChainBlock) = c.blocks
addrs(c::ChainBlock) = ones(Int, length(c))
usedbits(c::ChainBlock) = unique(vcat([usedbits(b) for b in subblocks(c)]...))
chsubblocks(pb::ChainBlock, blocks) = ChainBlock(blocks)
@forward ChainBlock.blocks Base.popfirst!, Base.pop!

YaoBase.isunitary(c::ChainBlock) = all(isunitary, c.blocks) || isunitary(mat(c))
YaoBase.isreflexive(c::ChainBlock) = (iscommute(c.blocks...) && all(isreflexive, c.blocks)) || isreflexive(mat(c))
YaoBase.ishermitian(c::ChainBlock) = (all(isreflexive, c.blocks) && iscommute(c.blocks...)) || isreflexive(mat(c))

# Additional Methods for Chain
Base.push!(c::ChainBlock{N}, val::MatrixBlock{N}) where N = (push!(c.blocks, val); c)

function Base.push!(c::ChainBlock{N, T}, val::Function) where {N, T}
    push!(c, val(N))
end

# append!(c::ChainBlock, list) = (append!(c.blocks, list); c)
# prepend!(c::ChainBlock, list) = (prepend!(c.blocks, list); c)
function Base.append!(c::ChainBlock, list)
    for blk in list
        push!(c, blk)
    end
    c
end

function Base.prepend!(c::ChainBlock, list)
    for blk in list[end:-1:1]
        insert!(c, 1, blk)
    end
    c
end

mat(c::ChainBlock) = prod(x->mat(x), reverse(c.blocks))

function apply!(r::AbstractRegister, c::ChainBlock)
    for each in c.blocks
        apply!(r, each)
    end
    r
end

function cache_key(c::ChainBlock)
    [cache_key(each) for each in c.blocks]
end

function Base.hash(c::ChainBlock, h::UInt)
    hashkey = hash(objectid(c), h)
    for each in c.blocks
        hashkey = hash(each, hashkey)
    end
    hashkey
end

function Base.:(==)(lhs::ChainBlock{N, T}, rhs::ChainBlock{N, T}) where {N, T}
    (length(lhs.blocks) == length(rhs.blocks)) && all(lhs.blocks .== rhs.blocks)
end

function print_block(io::IO, x::ChainBlock)
    printstyled(io, "chain"; bold=true, color=color(ChainBlock))
end
