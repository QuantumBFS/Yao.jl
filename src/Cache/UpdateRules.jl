export update_cache

function update_cache(c::Cached, signal::Int; recursive=false)
    update_cache(c, cache_type(c), cache_matrix(c), signal, recursive)
end

function update_cache(c::Cached, ::Type{CT}, val, signal, recursive::Bool) where CT
    push!(global_cache(CT), c.block, val, signal)
    c
end

# update composite blocks recursively
# NOTE: add an iterator interface for composite blocks to polish this part

function update_cache(c::Cached{BT}, ::Type{CT}, val, signal, recursive::Bool) where {BT <: ChainBlock, CT}
    push!(global_cache(CT), c.block, val, signal)
    for each in c.block.blocks
        update_cache(each, signal, recursive=recursive)
    end
    c
end

function update_cache(c::Cached{BT}, ::Type{CT}, val, signal, recursive::Bool) where {BT <: KronBlock, CT}
    push!(global_cache(CT), c.block, val, signal)

    for (line, each) in c.block.kvstore
        update_cache(each, signal, recursive=recursive)
    end
    c
end

function update_cache(c::Cached{BT}, ::Type{CT}, val, signal, recursive::Bool) where {BT <: ControlBlock, CT}
    push!(global_cache(CT), c.block, val, signal)
    update_cache(c.block, signal, recursive=recursive)
    c
end