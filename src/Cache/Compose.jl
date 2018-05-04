# TODO: cache_all

"""
    update_cache(composite, T, vals, level)

update `vals` for cached blocks inside a composite block
"""
function update_cache(block::ChainBlock, ::Type{T}, vals::Vector{T}, level::UInt) where T
    for (each, val) in zip(block.list, vals)
        push!(global_cache(T), each, val, level)
    end
    block
end

function update_cache(block::KronBlock, ::Type{T}, vals::Vector{T}, level::UInt) where T
    for (each, val) in zip(values(block), vals)
        push!(global_cache(T), each, val, level)
    end
    block
end

function update_cache(block::ChainBlock, level::UInt)
    if iscacheable(block, level) # update compsite block first
        update_cache(block, cache_type(block), cache_matrix(block), level)
    end

    # then update its children if possible
    for each in block.list
        iscacheable(block, level) && update_cache(each, level)
    end
    block
end


########
# Hash
########

function Hash(c::ChainBlock, h::UInt)
    hashkey = hash(object_id(c), h)
    for each in c.blocks
        hashkey = hash(each, hashkey)
    end
    hashkey
end

==(lhs::ChainBlock, rhs::ChainBlock) = false
==(lhs::ChainBlock{N, T}, rhs::ChainBlock{N, T}) where {N, T} = all(lhs.blocks .== rhs.blocks)


function hash(block::KronBlock{N, T}, h::UInt) where {N, T}
    hashkey = hash(object_id(block), h)
    for each in values(block)
        hashkey = hash(each, hashkey)
    end
    return hashkey
end

==(lhs::KronBlock, rhs::KronBlock) = false
==(lhs::KronBlock{N, T}, rhs::KronBlock{N, T}) where {N, T} = (lhs.kvstore == rhs.kvstore)

