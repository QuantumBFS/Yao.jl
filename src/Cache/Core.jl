import Base: empty!, push!

# default method for cache matrix
"""
    cache_type(block) -> type

get the type that this block will use for cache.
"""
cache_type(block::PureBlock{N, T}) where {N, T} = SparseMatrixCSC{T, Int}

"""
    cache_matrix(block)
"""
cache_matrix(block::PureBlock) = sparse(block)

# hash methods
@inline object_hash(block::PureBlock) = object_id(block)
@inline param_hash(block::PureBlock) = hash(block)


"""
    CacheElement{MatrixType}

A cache element
"""
mutable struct CacheElement{TM <: AbstractMatrix}
    level::UInt
    data::Dict{UInt, TM}
end

CacheElement(::Type{TM}, level::UInt) where TM =
    CacheElement{TM}(level, Dict{UInt, TM}())

# interface
@inline iscacheable(cache::CacheElement, level::UInt) = cache.level < level

function push!(cache::CacheElement{TM}, key::UInt, val::TM) where TM
    cache.data[key] = val
    cache
end

function push!(cache::CacheElement{TM}, key::UInt, val::TM, level::UInt) where TM
    iscacheable(cache, level) || return cache
    push!(cache, key, val)
end

# TODO: better exception
pull(cache::CacheElement, key::UInt) = cache.data[key]

# shortcuts
function iscacheable(cache::CacheElement, block::PureBlock, level::UInt)
    iscacheable(cache, param_hash(block), level)
end

function push!(cache::CacheElement{TM}, block::PureBlock, val::TM, level::UInt) where TM
    push!(cache, param_hash(block), val, level)
end

function pull(cache::CacheElement, block::PureBlock)
    pull(cache, param_hash(block))
end

function setlevel!(cache::CacheElement, level::UInt)
    cache.level = level
    cache
end

empty!(cache::CacheElement) = empty!(cache.data)

###################
# Cache Servers
###################

abstract type AbstractCacheServer end

"""
    CacheServer{K, V} <: AbstractCacheServer

A naive implementation of a key value
storage.

## NOTE

the key value storage will store the
matrix form by given cache level with `cache`.
This do not have `!` because we will use
a const global cache server by default like
the MT1993 builtin random number generator (RNG).
cache will only change the state of a global
constant.
"""
struct CacheServer{TM} <: AbstractCacheServer
    kvstore::Dict{UInt, CacheElement{TM}}
end

CacheServer(::Type{TM}) where TM = CacheServer(Dict{UInt, CacheElement{TM}}())

########################
# Direct Access Methods
########################

function iscacheable(server::CacheServer, key::UInt, level::UInt)
    key in keys(server.kvstore) || return false
    iscacheable(server.kvstore[key], level)
end

function setlevel!(server::CacheServer{TM}, key::UInt, level::UInt) where TM
    if !(key in keys(server.kvstore))
        setlevel!(server.kvstore[key], level)
    end
    server
end

"""
    cache!(server, key, level) -> server

add a new cacheable block with cache level `level`
by upload its `key` to the server.
"""
function cache!(server::CacheServer{TM}, key::UInt, level::UInt) where TM
    if !(key in keys(server.kvstore))
        server.kvstore[key] = CacheElement(TM, level)
    end
    server
end

"""
    push!(server, key, pkey, val, level) -> server

push (block, level) in hash key form to the server. update original
cache with `val`. if input level is greater than stored level (input > stored).
"""
function push!(server::CacheServer{TM}, key::UInt, pkey::UInt, val::TM, level::UInt) where TM
    if key in keys(server.kvstore)
        push!(server.kvstore[key], pkey, val, level)
    end
    server
end

"""
    pull(server, key, pkey) -> valtype

get block's cache by (key, pkey)
"""
@inline function pull(server::CacheServer, key::UInt, pkey::UInt)
    pull(server.kvstore[key], pkey)
end

"""
    iscaheable(server, block, level) -> Bool

whether this block is cacheable with current cache level.
"""
@inline function iscacheable(server::CacheServer, block::PureBlock, level::UInt)
    iscacheable(server, object_hash(block), level)
end

"""
    setlevel!(server, block, level)

set block's cache level
"""
@inline function setlevel!(server::CacheServer, block::PureBlock, level::UInt)
    setlevel!(server, object_hash(block), level)
end

"""
    cache!(server, block, level) -> server

add a new cacheable block with cache level `level` to the server.
"""
@inline function cache!(server::CacheServer{TM}, block::PureBlock, level::UInt) where TM
    cache!(server, object_hash(block), level)
end

"""
    push!(server, block, val, level) -> server

push `val` to cache server, it will be cached if `level` is greater
than stored level. Or it will do nothing.
"""
@inline function push!(server::CacheServer{TM}, block::PureBlock, val::TM, level::UInt) where TM
    push!(server, object_hash(block), param_hash(block), val, level)
end

"""
    pull(server, block)

pull current block's cache from server
"""
@inline function pull(server::CacheServer, block::PureBlock)
    pull(server, object_hash(block), param_hash(block))
end

#############################################
# Interface #################################
#############################################

iscacheable(block::PureBlock, signal::Int=1) = iscacheable(block, cache_type(block), UInt(signal))
iscacheable(block::PureBlock, ::Type{CT}, signal::UInt) where CT = iscacheable(global_cache(CT), block, signal)


const GLOBAL_CACHE_POOL = Dict{DataType, CacheServer}()

function global_cache(::Type{T}) where T
    if T in keys(GLOBAL_CACHE_POOL)
        return GLOBAL_CACHE_POOL[T]
    else
        server = CacheServer(T)
        GLOBAL_CACHE_POOL[T] = server
        return server
    end
end


struct Cached{BT, N, T} <: PureBlock{N, T}
    block::BT
end

Cached(block::BT) where {N, T, BT <: PureBlock{N, T}} = Cached{BT, N, T}(block)

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


include("CacheRules.jl")
include("UpdateRules.jl")

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
