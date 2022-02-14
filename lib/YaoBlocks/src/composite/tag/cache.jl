using YaoBase, CacheServers
export CacheFragment, CachedBlock, update_cache
export cache, pull, update!, update_cache, clearall!, iscached, iscacheable

"""
    CacheFragment{BT, K, MT}

A fragment that will be stored for each cached block (of type `BT`) on a cache server.
"""
struct CacheFragment{BT,K,MT}
    ref::BT
    storage::Dict{K,MT}

    function CacheFragment{BT,K,MT}(x::BT) where {BT,K,MT}
        new{BT,K,MT}(x, Dict{K,MT}())
    end

    function CacheFragment{BT,K}(x::BT) where {BT} where {K}
        new{BT,K,cache_type(BT)}(x, Dict{K,cache_type(BT)}())
    end

    function CacheFragment(x::BT) where {BT}
        CacheFragment{BT,typeof(cache_key(x))}(x)
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
    CachedBlock{ST, BT, D} <: TagBlock{BT, D}

A label type that tags an instance of type `BT`. It forwards
every methods of the block it contains, except [`mat`](@ref)
and [`apply!`](@ref), it will cache the matrix form whenever
the program has.
"""
struct CachedBlock{ST,BT,D} <: TagBlock{BT,D}
    server::ST
    content::BT
    level::Int

    function CachedBlock(server::ST, x::BT, level::Int) where {ST,D,BT<:AbstractBlock{D}}
        alloc!(server, x, CacheFragment(x))
        new{ST,BT,D}(server, x, level)
    end
end

CacheServers.iscached(c::CachedBlock) = iscached(c.server, c.content)
iscacheable(c::CachedBlock) = iscacheable(c.server, c.content)
chsubblocks(cb::CachedBlock, blk::AbstractBlock) = CachedBlock(cb.server, blk, cb.level)
occupied_locs(x::CachedBlock) = occupied_locs(content(x))
PropertyTrait(::CachedBlock) = PreserveAll()

function update_cache(::Type{T}, c::CachedBlock) where {T}
    if !iscached(c.server, c.content)
        m = mat(T, c.content)
        push!(c.server, m, c.content)
    end
    return c
end

CacheServers.clear!(x::AbstractBlock) = x
CacheServers.clear!(c::CachedBlock) = (clear!(c.server, c.content); c)

function mat(::Type{T}, c::CachedBlock) where {T}
    if !iscached(c.server, c.content)
        m = mat(T, c.content)
        push!(c.server, m, c.content)
        return m
    end
    return pull(c)
end

function CacheServers.pull(c::CachedBlock)
    return pull(c.server, c.content)
end

function _apply!(r::AbstractArrayReg{D,T}, c::CachedBlock, signal) where {D,T}
    if signal > c.level
        r.state .= mat(T, c) * r
    else
        _apply!(r, c.content)
    end
    return r
end

_apply!(r::AbstractRegister, c::CachedBlock) = _apply!(r, c.content)
_apply!(r::AbstractArrayReg{D,T}, c::CachedBlock) where {D,T} = (r.state .= mat(T, c) * r.state; r)

Base.similar(c::CachedBlock, level::Int) = CachedBlock(c.server, c.content, level)
Base.copy(c::CachedBlock) = CachedBlock(c.server, copy(c.content), c.level)
Base.length(x::CachedBlock) = length(content(x))
Base.getindex(c::CachedBlock, index...) = getindex(content(c), index...)
Base.setindex!(c::CachedBlock, val, index...) = setindex!(content(c), val, index...)
Base.iterate(c::CachedBlock) = iterate(content(c))
Base.iterate(c::CachedBlock, st) = iterate(content(c), st)
Base.eltype(x::CachedBlock) = eltype(content(x))


const DefaultCacheServer = get_server(AbstractBlock, CacheFragment)

cache(x::Function, level::Int = 1; recursive = false) =
    n -> cache(x(n), level; recursive = recursive)

"""
    cache(x[, level=1; recursive=false])

Create a [`CachedBlock`](@ref) with given block `x`, which will cache the matrix of `x` for the first time
it calls [`mat`](@ref), and use the cached matrix in the following calculations.

# Example

```jldoctest; setup=:(using YaoBlocks)
julia> cache(control(3, 1, 2=>X))
nqudits: 3
[cached] control(1)
   └─ (2,) X


julia> chain(cache(control(3, 1, 2=>X)), repeat(H))
nqudits: 3
chain
└─ [cached] control(1)
      └─ (2,) X

```
"""
function cache(x::AbstractBlock, level::Int = 1; recursive = false)
    return cache(DefaultCacheServer, x, level, recursive = recursive)
end

function clearall!(x::CachedBlock)
    return clear!(x)
end

function clearall!(x::CachedBlock{ST,BT}) where {ST,BT<:CompositeBlock}
    for each in subblocks(x.content)
        clearall!(each)
    end
    clear!(x)
    return x
end

function cache(
    server::AbstractCacheServer,
    x::AbstractBlock,
    level::Int;
    recursive::Bool = false,
)
    return CachedBlock(server, x, level)
end

function cache(
    server::AbstractCacheServer,
    x::ChainBlock,
    level::Int;
    recursive::Bool = false,
)
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

function cache(
    server::AbstractCacheServer,
    block::KronBlock,
    level::Int;
    recursive::Bool = false,
)
    if recursive
        x = similar(block)
        for (k, v) in block
            x[k] = cache(server, v, level, recursive = recursive)
        end
    else
        x = block
    end

    return CachedBlock(server, x, level)
end
