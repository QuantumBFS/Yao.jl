module CacheServers

using Compat

export get_server, pull, alloc!
import Base: push!, delete!, clear!, getindex, show

include("Core.jl")
include("Default.jl")


@static if haskey(ENV, "DefaultCacheServerType")
    const DefaultServerType = parse(ENV["DefaultCacheServerType"])
else
    const DefaultServerType = DefaultServer
end

const ServerPool = Dict()

get_server(::Type{K}, ::Type{ELT}, params...; kwargs...) where {K, ELT} =
    get_server(DefaultServerType, K, ELT, params...; kwargs...)

function get_server(::Type{ST}, ::Type{K}, ::Type{ELT}, params...; kwargs...) where {ST, K, ELT}
    if ST{K, ELT} in keys(ServerPool)
        ServerPool[ST{K, ELT}]
    else
        ServerPool[ST{K, ELT}] = ST{K, ELT}(params...; kwargs...)
    end
end

end
