export AbstractCacheServer

"""
    AbstractCacheServer{K, ELT}
"""
abstract type AbstractCacheServer{K, ELT} end

"""
    alloc!(server, object, storage) -> server

alloc new storage on the server.
"""
function alloc!(s::AbstractCacheServer, object, storage)
    throw(MethodError(alloc!, (s, object, storage)))
end

"""
    iscacheable(server, object)

check if there is available space to storage this object's value. (if this object
was allocated on the server before.).
"""
function iscacheable(s::AbstractCacheServer, object)
    throw(MethodError(iscacheable, (s, object)))
end

"""
    iscached(server, object, [params...])

check if this object (with params) is already cached.
"""
function iscached(s::AbstractCacheServer, object, params...)
    throw(MethodError(push!, (s, object, params...)))
end

"""
    push!(server, val, object) -> server

push `val` to the storage of `object` in the `server`.
"""
function push!(s::AbstractCacheServer, val, object)
    throw(MethodError(push!, (s, val, object)))
end

"""
    update!(storage, val) -> storage
"""
function update!(storage, val)
    throw(MethodError(update!, (storage, val)))
end

"""
    pull(server, object, params...) -> value

pull `object` storage from server.
"""
function pull(server::AbstractCacheServer, object, params...)
    throw(MethodError(pull, (server, object, params...)))
end

# getindex will call pull by default
function getindex(server::AbstractCacheServer, index)
    pull(server, index)
end

"""
    delete!(server, object) -> server

delete this object from the server. (the storage will be deleted)
"""
function delete!(server::AbstractCacheServer, object)
    throw(MethodError(clear!, (server, object)))
end

"""
    clear!(server, object) -> server

clear the storage in the `server` of this `object`.
"""
function clear!(server::AbstractCacheServer, object)
    throw(MethodError(clear!, (server, object)))
end
