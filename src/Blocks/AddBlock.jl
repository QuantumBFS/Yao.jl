export AddBlock

"""
    AddBlock{N, T} <: CompositeBlock{N, T}

Adding multiple blocks into one.
"""
struct AddBlock{N, T} <: CompositeBlock{N, T}
    blocks::Vector{MatrixBlock{N}}
end
# type promotion
function AddBlock(blocks::Vector{<:MatrixBlock{N}}) where N
    T = promote_type(collect(datatype(each) for each in blocks)...)
    AddBlock{N, T}(blocks)
end
function AddBlock(blocks::MatrixBlock{N}...) where N
    AddBlock(collect(blocks))
end

function copy(c::AddBlock{N, T}) where {N, T}
    AddBlock{N, T}(copy(c.blocks))
end

function similar(c::AddBlock{N, T}) where {N, T}
    AddBlock{N, T}(empty!(similar(c.blocks)))
end

# Additional Methods for Composite Blocks
@forward AddBlock.blocks lastindex, iterate, length, eltype, eachindex, popfirst!, pop!
getindex(c::AddBlock, index) = getindex(c.blocks, index)
getindex(c::AddBlock, index::Union{UnitRange, Vector}) = AddBlock(getindex(c.blocks, index))
setindex!(c::AddBlock{N}, val::MatrixBlock{N}, index::Integer) where N = (setindex!(c.blocks, val, index); c)
insert!(c::AddBlock{N}, index::Integer, val::MatrixBlock{N}) where N = (insert!(c.blocks, index, val); c)
adjoint(blk::AddBlock) = typeof(blk)(map(adjoint, subblocks(blk)))

## Iterate contained blocks
subblocks(c::AddBlock) = c.blocks
chsubblocks(pb::AddBlock, blocks) = AddBlock(blocks)
usedbits(c::AddBlock) = unique(vcat([usedbits(b) for b in subblocks(c)]...))

ishermitian(ad::AddBlock) = all(ishermitian, ad.blocks) || ishermitian(mat(ad))

# Additional Methods for AddBlock
push!(c::AddBlock{N}, val::MatrixBlock{N}) where N = (push!(c.blocks, val); c)

function push!(c::AddBlock{N, T}, val::Function) where {N, T}
    push!(c, val(N))
end

function append!(c::AddBlock, list)
    for blk in list
        push!(c, blk)
    end
    c
end

function prepend!(c::AddBlock, list)
    for blk in list[end:-1:1]
        insert!(c, 1, blk)
    end
    c
end

mat(c::AddBlock) = mapreduce(x->mat(x), +, c.blocks)

function apply!(r::AbstractRegister, c::AddBlock)
    length(c) == 0 && return r
    length(c) == 1 && return apply!(r, c.blocks[])
    res = mapreduce(blk->apply!(copy(r), blk), +, c.blocks[1:end-1])
    apply!(r, c.blocks[end])
    r.state += res.state
    r
end

function cache_key(c::AddBlock)
    [cache_key(each) for each in c.blocks]
end

function hash(c::AddBlock, h::UInt)
    hashkey = hash(objectid(c), h)
    for each in c.blocks
        hashkey = hash(each, hashkey)
    end
    hashkey
end

function ==(lhs::AddBlock{N, T}, rhs::AddBlock{N, T}) where {N, T}
    (length(lhs.blocks) == length(rhs.blocks)) && all(lhs.blocks .== rhs.blocks)
end

function print_block(io::IO, x::AddBlock)
    printstyled(io, "+"; bold=true, color=:red)
end
