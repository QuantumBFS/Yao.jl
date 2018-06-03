export cache, pull, update_cache

const DefaultCacheServer = get_server(MatrixBlock, CacheFragment)

function cache(x::MatrixBlock, level::Int=1; recursive=false)
    cache(DefaultCacheServer, x, level, recursive=recursive)
end

function clearall!(x::CachedBlock)
    clear!(x)
end

function clearall!(x::CachedBlock{ST, BT}) where {ST, BT <: CompositeBlock}
    for each in blocks(x.block)
        clear!(each)
    end
    clear!(x)
    x
end

function cache(server::AbstractCacheServer, x::MatrixBlock, level::Int; recursive::Bool=false)
    alloc!(server, x, CacheFragment(x))
    CachedBlock(server, x, level)
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

    alloc!(server, chain, CacheFragment(chain))
    CachedBlock(server, chain, level)
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

    alloc!(server, x, CacheFragment(x))
    CachedBlock(server, x, level)
end

function cache(server::AbstractCacheServer, block::Roller, level::Int; recursive::Bool=false)
    if recursive
        roller = Roller{N, T}(ntuple(x->cache(server, block[x], level, recursive=recursive), Val(M))...)
    else
        roller = block
    end

    alloc!(server, roller, CacheFragment(roller))
    CachedBlock(server, roller, level)
end


