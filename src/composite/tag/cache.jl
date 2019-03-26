using YaoBase, CacheServers
import YaoBase: @interface
export CacheFragment, CachedBlock, update_cache
export cache, pull, update!, update_cache, clearall!, iscached, iscacheable

"""
    CacheFragment{BT, K, MT}

A fragment that will be stored for each cached block (of type `BT`) on a cache server.
"""
struct CacheFragment{BT, K, MT}
    ref::BT
    storage::Dict{K, MT}

    function CacheFragment{BT, K, MT}(x::BT) where {BT, K, MT}
        new{BT, K, MT}(x, Dict{K, MT}())
    end

    function CacheFragment{BT, K}(x::BT) where BT where K
        new{BT, K, cache_type(BT)}(x, Dict{K, cache_type(BT)}())
    end

    function CacheFragment(x::BT) where BT
        CacheFragment{BT, typeof(cache_key(x))}(x)
    end
end

# default update rule
function CacheServers.update!(frag::CacheFragment, val)
    if !iscached(frag)
        frag.storage[cache_key(frag.ref)] = val
    end
    frag
end

CacheServers.iscached(frag::CacheFragment) = cache_key(frag.ref) in keys(frag.storage)
CacheServers.pull(frag::CacheFragment) = frag.storage[cache_key(frag.ref)]
CacheServers.clear!(frag::CacheFragment) = (empty!(frag.storage); frag)

"""
    CachedBlock{ST, BT, N, T} <: AbstractContainer{N, T, BT}

A label type that tags an instance of type `BT`. It forwards
every methods of the block it contains, except [`mat`](@ref)
and [`apply!`](@ref), it will cache the matrix form whenever
the program has.
"""
struct CachedBlock{ST, BT, N, T} <: TagBlock{N, T, BT}
    server::ST
    content::BT
    level::Int

    function CachedBlock(server::ST, x::BT, level::Int) where {ST, N, T, BT <: AbstractBlock{N, T}}
        alloc!(server, x, CacheFragment(x))
        new{ST, BT, N, T}(server, x, level)
    end
end

CacheServers.iscached(c::CachedBlock) = iscached(c.server, c.content)
iscacheable(c::CachedBlock) = iscacheable(c.server, c.content)
chsubblocks(cb::CachedBlock, blk::AbstractBlock) = CachedBlock(cb.server, blk, cb.level)
occupied_locs(x::CachedBlock) = occupied_locs(parent(x))
PreserveStyle(::CachedBlock) = PreserveAll()

function update_cache(c::CachedBlock)
    if !iscached(c.server, c.content)
        m = dropzeros!(mat(c.content))
        push!(c.server, m, c.content)
    end
    return c
end

CacheServers.clear!(x::AbstractBlock) = x
CacheServers.clear!(c::CachedBlock) = (clear!(c.server, c.content); c)

function mat(c::CachedBlock)
    if !iscached(c.server, c.content)
        m = dropzeros!(mat(c.content))
        push!(c.server, m, c.content)
        return m
    end
    return pull(c)
end

function CacheServers.pull(c::CachedBlock)
    return pull(c.server, c.content)
end

function apply!(r::AbstractRegister, c::CachedBlock, signal)
    if signal > c.level
        r.state .= mat(c) * r
    else
        apply!(r, c.content)
    end
    return r
end
apply!(r::AbstractRegister, c::CachedBlock) = (r.state .= mat(c) * r; r)

Base.similar(c::CachedBlock, level::Int) = CachedBlock(c.server, c.content, level)
Base.copy(c::CachedBlock) = CachedBlock(c.server, copy(c.content), c.level)


const DefaultCacheServer = get_server(AbstractBlock, CacheFragment)

cache(x::Function, level::Int=1; recursive=false) = n->cache(x(n), level; recursive=recursive)

function cache(x::AbstractBlock, level::Int=1; recursive=false)
    return cache(DefaultCacheServer, x, level, recursive=recursive)
end

function clearall!(x::CachedBlock)
    return clear!(x)
end

function clearall!(x::CachedBlock{ST, BT}) where {ST, BT <: CompositeBlock}
    for each in subblocks(x.content)
        clearall!(each)
    end
    clear!(x)
    return x
end

function cache(server::AbstractCacheServer, x::AbstractBlock, level::Int; recursive::Bool=false)
    return CachedBlock(server, x, level)
end

function cache(server::AbstractCacheServer, x::ChainBlock, level::Int; recursive::Bool=false)
    if recursive
        chain = similar(x)
        for (i, each) in enumerate(block)
            chain[i] = cache(server, each, level, recursive)
        end
    else
        chain = x
    end

    return CachedBlock(server, chain, level)
end

function cache(server::AbstractCacheServer, block::KronBlock, level::Int; recursive::Bool=false)
    if recursive
        x = similar(block)
        for (k, v) in block
            x[k] = cache(server, v, level, recursive=recursive)
        end
    else
        x = block
    end

    return CachedBlock(server, x, level)
end

function cache(server::AbstractCacheServer, block::Roller, level::Int; recursive::Bool=false)
    if recursive
        roller = Roller{T}(ntuple(x->cache(server, block[x], level, recursive=recursive), Val(M))...)
    else
        roller = block
    end

    return CachedBlock(server, roller, level)
end
