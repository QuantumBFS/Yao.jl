const MAX_CACHE_NUM = 10

struct Cache{N, L, T, BT <: PureBlock{N, T}, TA <: AbstractMatrix{T}} <: AbstractCache{N, L, T}
    block::BT
    cache::Dict{BT, TA}
end

Cache(::Type{TA}, block::BT, level::Int) where {TA, N, T, BT <: PureBlock{N, T}} =
    Cache{N, level, T, BT, TA{T}}(block, Dict())
Cache(block::PureBlock, level::Int) =
    Cache(SparseMatrixCSC{T, Int} where T, block)

export cache

function cache(block::PureBlock; level::Int=0, method=SparseMatrixCSC{T, Int} where T)
    Cache(method, block, level)
end

get_cache(block::Cache) = block.cache

isunitary(block::Cache{N, L, T, BT}) where {N, L, T, BT} = isunitary(BT)

function apply!(reg::Register, block::Cache)
    if block.block in block.cache
        reg.state .= block.cache[block.block] * state(reg)
    else
        apply!(reg, block.block)
        block.cache[copy(reg)] = sparse(block.block)
    end
    reg
end

cacheable(cache_block::Cache{N, L}, level, force) where {N, L} =
    force || (!(cache_block.block in keys(cache_block.cache)) && level > L)

# force cache this cache block
function force_cache!(cache_block::Cache)
    cache_block.cache[copy(cache_block.block)] =
        sparse(cache_block.block)
    cache_block
end

function force_cache!(cache_block::Cache{N, L, T, BT, TA}) where {N, L, T, BT <: PureBlock{N, T}, TA <: Matrix{T}}
    cache_block.cache[copy(cache_block.block)] =
        full(cache_block.block)
    cache_block
end

function cache!(cache_block::Cache; level=1, force=false)
    if cacheable(cache_block, level, force)
        force_cache!(cache_block)
    end
    cache_block
end

update!(block::Cache, params...) = update!(block.block, params...)
