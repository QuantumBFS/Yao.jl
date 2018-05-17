struct Cached{BT, N, T} <: MatrixBlock{N, T}
    block::BT
end

Cached(block::BT) where {N, T, BT <: MatrixBlock{N, T}} = Cached{BT, N, T}(block)

# forward cache configuration
cache_matrix(c::Cached) = cache_matrix(c.block)
cache_type(c::Cached) = cache_type(c.block)

# overload cache trait
iscacheable(c::Cached, signal) = iscacheable(c.block, signal)

export iscached
iscached(c::Cached) = iscached(global_cache(cache_type(c.block)), c.block)

# for block which is not cached this is equal
apply!(reg::Register, c, signal)= apply!(reg, c)

function sparse(c::Cached)
    if !iscached(c)
        mat = sparse(c)
        update_cache(c, mat)
        return mat
    end
    pull(c)
end

function full(c::Cached)
    if !iscached(c)
        mat = full(c)
        update_cache(c, mat)
        return mat
    end

    full(pull(c))
end

function apply!(reg::Register, c::Cached, signal::UInt)
    if iscached(c)
        reg.state .= pull(c) * reg
        return reg
    end

    if iscacheable(c, signal)
        mat = cache_matrix(c) # avoid extra uploading
        update_cache(c, mat, signal)
        reg.state .= mat * reg
    else
        apply!(reg, c.block)
    end

    reg
end

dispatch!(c::Cached, params...) = (dispatch!(c.block, params...); c)

export pull

pull(c::Cached) = pull(cache_type(c.block), c)
function pull(::Type{CT}, c::Cached) where CT
    pull(global_cache(CT), c.block)
end

export setlevel

function setlevel(c::Cached, level)
    setlevel(c.block, cache_type(c.block), level)
end

function setlevel(c::Cached, ::Type{CT}, level) where CT
    setlevel!(global_cache(CT), c.block, level)
end

function show(io::IO, c::Cached)
    print(io, "(Cached) ")
    print(io, c.block)
end
