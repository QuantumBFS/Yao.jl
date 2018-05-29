export update_cache

# do nothing for other untagged blocks
update_cache(c, signal; recursive=false) = c

function update_cache(c::CompositeBlock, signal::Int; recursive=false)
    for each in blocks(c)
        update_cache(each, signal; recursive=recursive)
    end
end

# dispatch according to cache signature
function update_cache(c::Cached, signal::Int; recursive=false)
    update_cache(c, cache_matrix(c), signal; recursive=recursive)
end

# force update
update_cache(c; recursive=false) = c

function update_cache(c::CompositeBlock; recursive=false)
    for each in blocks(c)
        update_cache(each; recursive=recursive)
    end
end

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
        for i in eachindex(c.block)
            update_cache(c.block[i], signal, recursive=true)
        end
    end
    c
end

# force update
function update_cache(c::Cached{BT}, ::Type{CT}, val, recursive::Bool) where {BT <: CompositeBlock, CT}
    push!(global_cache(CT), c.block, val)
    if recursive
        for each in blocks(c.block)
            update_cache(each, recursive=true)
        end
    end
    c
end
