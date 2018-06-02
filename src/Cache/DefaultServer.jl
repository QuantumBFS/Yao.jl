export DefaultServer

struct DefaultServer{TM} <: AbstractCacheServer
    storage::Dict{UInt, CacheElement{TM}}
end

DefaultServer(::Type{TM}) where TM = DefaultServer(Dict{UInt, CacheElement{TM}}())

getindex(s::DefaultServer, uint::UInt) = getindex(s.storage, uint)
getindex(s::DefaultServer, block::MatrixBlock) = getindex(s.storage, objectid(block))

########################
# Direct Access Methods
########################

function iscacheable(server::DefaultServer, k::UInt, level::UInt)
    k in keys(server.storage) || return false
    iscacheable(server.storage[k], level)
end

function iscacheable(server::DefaultServer, k::UInt)
    k in keys(server.storage)
end

function iscached(server::DefaultServer, block::MatrixBlock)
    k = objectid(block)
    k in keys(server.storage) || return false
    iscached(server.storage[k], block)
end

function setlevel!(server::DefaultServer{TM}, k::UInt, level::UInt) where TM
    if !(k in keys(server.storage))
        setlevel!(server.storage[k], level)
    end
    server
end

"""
    cache!(server, key, level) -> server

add a new cacheable block with cache level `level`
by upload its `key` to the server.
"""
function cache!(server::DefaultServer{TM}, key::UInt, level::UInt) where TM
    if !(key in keys(server.storage))
        server.storage[key] = CacheElement(TM, level)
    end
    server
end

"""
    push!(server, key, pkey, val[, level]) -> server

push (block, level) in hash key form to the server. update original
cache with `val`. if input level is greater than stored level (input > stored).
"""
function push!(server::DefaultServer{TM}, key::UInt, pkey::MatrixBlock, val::TM, level::UInt) where TM
    if key in keys(server.storage)
        push!(server.storage[key], pkey, val, level)
    end
    server
end

# force push
function push!(server::DefaultServer{TM}, key::UInt, pkey::MatrixBlock, val::TM) where TM
    if key in keys(server.storage)
        push!(server.storage[key], pkey, val)
    end
    server
end

"""
    pull(server, key, pkey) -> valtype

get block's cache by (key, pkey)
"""
@inline function pull(server::DefaultServer, key::UInt, pkey::MatrixBlock)
    pull(server.storage[key], pkey)
end

##########################
# Wrap to call objectid
##########################

"""
    iscaheable(server, block, level) -> Bool

whether this block is cacheable with current cache level.
"""
@inline function iscacheable(server::DefaultServer, block::MatrixBlock, level::UInt)
    iscacheable(server, objectid(block), level)
end

@inline function iscacheable(server::DefaultServer, block::MatrixBlock)
    iscacheable(server, objectid(block))
end

"""
    setlevel!(server, block, level)

set block's cache level
"""
@inline function setlevel!(server::DefaultServer, block::MatrixBlock, level::UInt)
    setlevel!(server, objectid(block), level)
end

"""
    cache!(server, block, level) -> server

add a new cacheable block with cache level `level` to the server.
"""
@inline function cache!(server::DefaultServer{TM}, block::MatrixBlock, level::UInt) where TM
    cache!(server, objectid(block), level)
end

"""
    push!(server, block, val, level) -> server

push `val` to cache server, it will be cached if `level` is greater
than stored level. Or it will do nothing.
"""
@inline function push!(server::DefaultServer{TM}, block::MatrixBlock, val::TM, level::UInt) where TM
    push!(server, objectid(block), block, val, level)
end

# force push
@inline function push!(server::DefaultServer{TM}, block::MatrixBlock, val::TM) where TM
    push!(server, objectid(block), block, val)
end

"""
    pull(server, block)

pull current block's cache from server
"""
@inline function pull(server::DefaultServer, block::MatrixBlock)
    pull(server, objectid(block), block)
end

@inline function empty!(server::DefaultServer, block::MatrixBlock)
    empty!(server[block])
end

function empty!(server::DefaultServer)
    empty!(server.storage)
end

function show(io::IO, c::DefaultServer{TM}) where TM
    println(io, "Default Server {$TM}")
    print(io, "entries: ", length(values(c.storage)))
end
