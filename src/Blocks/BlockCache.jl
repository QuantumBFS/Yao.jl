include("CacheFragment.jl")
include("CachedBlock.jl")

# move following to interface
# set up default cache server
# export DefaultBlockServer
# const DefaultBlockServer = DefaultServer{MatrixBlock, CacheFragment}()

# default cache for primitive blocks
# cache(x::MatrixBlock) = cache(DefaultBlockServer, x)

# function cache(server::AbstractCacheServer, x::PrimitiveBlock)
#     alloc!(server, x, CacheFragment(x))
#     CachedBlock(server, x)
# end

# pull(x::MatrixBlock) = pull(DefaultBlockServer, x)
# function update_cache(x::MatrixBlock) end
# function clear_cache(x::MatrixBlock) end
