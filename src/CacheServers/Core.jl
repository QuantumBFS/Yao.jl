export AbstractCacheServer

"""
    AbstractCacheServer{K, ELT}
"""
abstract type AbstractCacheServer{K, ELT} end

"""
    alloc!(server, object, storage) -> server

alloc new storage on the server.
"""
function alloc!(::AbstractCacheServer, object, storage) end

"""
    iscacheable(server, object)

check if there is available space to storage this object's value. (if this object
was allocated on the server before.).
"""
function iscacheable(::AbstractCacheServer, object) end

"""
    iscached(server, object, [params...])

check if this object (with params) is already cached.
"""
function iscached(::AbstractCacheServer, object, params...) end

"""
    push!(server, val, object) -> server

push `val` to the storage of `object` in the `server`.
"""
function push!(::AbstractCacheServer, val, object) end

"""
    update!(storage, val) -> storage
"""
function update!(storage, val)
    Compat.@warn "You need to implement update! method for $(typeof(storage)) to enable cache."
end

"""
    pull(server, object, params...) -> value

pull `object` storage from server.
"""
function pull(server::AbstractCacheServer, object, params...)
    Compat.@warn "You need to implement pull method for $(typeof(object)) before pull it from server."
end

# getindex will call pull by default
function getindex(server::AbstractCacheServer, index)
    pull(server, index)
end

"""
    delete!(server, object) -> server

delete this object from the server. (the storage will be deleted)
"""
function delete!(::AbstractCacheServer, object) end

"""
    clear!(server, object) -> server

clear the storage in the `server` of this `object`.
"""
function clear!(server::AbstractCacheServer, object) end
