export DefaultServer

struct DefaultServer{K, ELT} <: AbstractCacheServer{K, ELT}
    storage::Dict{UInt, ELT} # objectid => element

    DefaultServer{K, ELT}() where K where ELT = new{K, ELT}(Dict{UInt, ELT}())
end

function alloc!(server::DefaultServer{K}, object::K, fragment) where K
    server.storage[objectid(object)] = fragment
    server
end

function iscacheable(server::DefaultServer{K}, object::K) where K
    objectid(object) in keys(server.storage)
end

function iscached(server::DefaultServer{K}, object::K, params...) where K
    iscacheable(server, object) && iscached(server.storage[objectid(object)], params...)
end

function push!(server::DefaultServer{K}, val, index::K) where K
    update!(server.storage[objectid(index)], val)
    server
end

function pull(server::DefaultServer{K}, object::K, params...) where K
    pull(server.storage[objectid(object)], params...)
end

function delete!(server::DefaultServer{K}, object::K) where K
    delete!(server.storage, objectid(object))
    server
end

function clear!(server::DefaultServer{K}, object::K) where K
    clear!(server.storage[objectid(object)])
    server
end

function show(io::IO, server::DefaultServer)

    @static if VERSION < v"0.7-"
        print(io, summary(server))
    else
        summary(io, server)
    end

    for (key, elem) in server.storage
        print(io, key, " => ", elem)
    end
end
