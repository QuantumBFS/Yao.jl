export update_cache

# do nothing for other untagged blocks
update_cache(c, signal; recursive=false) = c

# dispatch according to cache signature
function update_cache(c::Cached, signal::Int; recursive=false)
    update_cache(c, cache_type(c), cache_matrix(c), signal, recursive)
end

function update_cache(c::Cached, ::Type{CT}, val, signal, recursive::Bool) where CT
    push!(global_cache(CT), c.block, val, signal)
    c
end

# update composite blocks recursively
function update_cache(c::Cached{BT}, ::Type{CT}, val, signal, recursive::Bool) where {BT <: CompositeBlock, CT}
    push!(global_cache(CT), c.block, val, signal)
    if recursive
        map!(x->update_cache(x, signal, recursive=recursive), c.block, c.block)
    end
    c
end
