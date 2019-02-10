"""
    cache_type(::Type) -> DataType

A type trait that defines the element type that a [`CacheFragment`](@ref)
will use.
"""
cache_type(::Type{<:MatrixBlock}) = Any

"""
    cache_key(block)

Returns the key that identify the matrix cache of this block. By default, we
use the returns of [`parameters`](@ref) as its key.
"""
function cache_key end

include("CacheFragment.jl")
include("CachedBlock.jl")
