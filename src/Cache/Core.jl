abstract type AbstractCacheServer end


# default method for cache matrix
"""
    cache_type(block) -> type

get the type that this block will use for cache.
"""
cache_type(block::MatrixBlock{N, T}) where {N, T} = SparseMatrixCSC{T, Int}

"""
    cache_matrix(block)
"""
cache_matrix(block::MatrixBlock) = sparse(block)

import Base: empty!
