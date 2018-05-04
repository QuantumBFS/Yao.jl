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

