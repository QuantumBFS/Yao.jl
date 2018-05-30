export Cached

struct Cached{BT, N, T} <: MatrixBlock{N, T}
    block::BT
end

Cached(block::BT) where {N, T, BT <: MatrixBlock{N, T}} = Cached{BT, N, T}(block)

# forward cache configuration
cache_matrix(c::Cached) = cache_matrix(c.block)
cache_type(c::Cached) = cache_type(c.block)

# overload cache trait
iscacheable(c::Cached, signal::UInt) = iscacheable(c.block, signal)

export iscached
iscached(c::Cached) = iscached(cache_type(c), c)
iscached(::Type{CT}, c::Cached) where CT = iscached(global_cache(CT), c)
iscached(server::DefaultServer, c::Cached) = iscached(server, c.block)


# for block which is not cached this is equal
apply!(reg::Register, c, signal)= apply!(reg, c)

function mat(c::Cached)
    if !iscached(c)
        m = dropzeros!(sparse(c.block))
        update_cache(c, m)
        return m
    end
    pull(c)
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

function print_block(io::IO, c::Cached)
    print(io, "(Cached)")
    print_block(io, c.block)
end

#############################
# Direct Inherited Methods
#############################

apply!(reg::Register, c::Cached) = apply!(reg, c.block)
dispatch!(c::Cached, params...) = (dispatch!(c.block, params...); c)

getindex(c::Cached, index...) = getindex(c.block, index...)
setindex!(c::Cached, val, index...) = setindex!(c.block, val, index...)

start(c::Cached) = start(c.block)
next(c::Cached, st) = next(c.block, st)
done(c::Cached, st) = done(c.block, st)
length(c::Cached) = length(c.block)
eltype(c::Cached) = eltype(c.block)
blocks(c::Cached) = blocks(c.block)

import ..Blocks: print_subblocks

print_subblocks(io::IO, tree::Cached, depth, charset, active_levels) = print_subblocks(io, tree.block, depth, charset, active_levels)
