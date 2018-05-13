struct Cached{BT, N, T} <: MatrixBlock{N, T}
    block::BT
end

Cached(block::BT) where {N, T, BT <: MatrixBlock{N, T}} = Cached{BT, N, T}(block)

sparse(c::Cached) = sparse(c.block)
full(c::Cached) = full(c.block)
dispatch!(c::Cached) = dispatch!(c.block)

# for block which is not cached this is equal
apply!(reg::Register, c, signal)= apply!(reg, c)

function apply!(reg::Register, c::Cached, signal::UInt)
    if !iscacheable(c, signal)
        update_cache(c, signal)
    end

    mat = pull(c.block)
    reg.state .= mat * state(reg)
    reg
end

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
