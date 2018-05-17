export update_cache

# do nothing for other untagged blocks
update_cache(c, signal; recursive=false) = c

# dispatch according to cache signature
function update_cache(c::Cached, signal::Int; recursive=false)
    update_cache(c, cache_matrix(c), unsigned(signal), recursive=recursive)
end

# force update
function update_cache(c::Cached; recursive=false)
    update_cache(c, cache_matrix(c), recursive=recursive)
end

# update with given value
function update_cache(c::Cached, val, signal::Int; recursive=false)
    update_cache(c, cache_type(c), val, unsigned(signal), recursive)
end

function update_cache(c::Cached, val; recursive=false)
    update_cache(c, cache_type(c), val, recursive)
end

# Implementation

function update_cache(c::Cached, ::Type{CT}, val, signal::UInt, recursive::Bool) where CT
    push!(global_cache(CT), c.block, val, signal)
    c
end

# force update
function update_cache(c::Cached, ::Type{CT}, val, recursive::Bool) where CT
    push!(global_cache(CT), c.block, val)
    c
end

# update composite blocks recursively
function update_cache(c::Cached{BT}, ::Type{CT}, val, signal::UInt, recursive::Bool) where {BT <: CompositeBlock, CT}
    push!(global_cache(CT), c.block, val, signal)
    if recursive
        info("update composite block recursively")
        map(x->update_cache(x, signal, recursive=recursive), c.block)
    end
    c
end

function update_cache(c::Cached{BT}, ::Type{CT}, val, signal::UInt, recursive::Bool) where {BT <: KronBlock, CT}
    push!(global_cache(CT), c.block, val, signal)
    if recursive
        info("update recursively")
        for each in values(c.block)
            update_cache(each, cache_type(each), cache_matrix(each), unsigned(signal), recursive)
        end
    end
    c
end

# force update
function update_cache(c::Cached{BT}, ::Type{CT}, val, recursive::Bool) where {BT <: CompositeBlock, CT}
    push!(global_cache(CT), c.block, val)
    if recursive
        info("update composite block recursively")
        map(x->update_cache(x, recursive=recursive), c.block)
    end
    c
end

function update_cache(c::Cached{BT}, ::Type{CT}, val, recursive::Bool) where {BT <: KronBlock, CT}
    push!(global_cache(CT), c.block, val)
    if recursive
        info("update recursively")
        for each in values(c.block)
            update_cache(each, cache_type(each), cache_matrix(each), recursive)
        end
    end
    c
end
