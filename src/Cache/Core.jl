export AbstractCacheServer, cache_type, cache_matrix

abstract type AbstractCacheServer end


# default method for cache matrix
"""
    cache_type(block) -> type

get the type that this block will use for cache.
"""
function cache_type end

# cache_type(block::PrimitiveBlock{N, T}) where {N, T} = typeof(mat(block))


"""
    cache_matrix(block)
"""
cache_matrix(block::MatrixBlock) = mat(block)
