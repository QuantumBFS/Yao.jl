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

function cache(block::PureBlock, level::Int=0; method=SparseMatrixCSC{T, Int} where T)
    cache_type(block)(method, block, level)
end

get_cache(block::Cache) = block.cache

# cache inherit the same property from its content
isunitary(::Type{C}) where {N, L, T, BT, C <: Cache{N, L, T, BT}} = isunitary(BT)
isunitary(block::Cache) = isunitary(block.block)

function apply!(reg::Register, block::Cache)
    if block.block in block.cache
        reg.state .= block.cache[block.block] * state(reg)
    else
        apply!(reg, block.block)
        block.cache[copy(reg)] = sparse(block.block)
    end
    reg
end

cacheable(block::AbstractBlock) = false
cacheable(block::AbstractBlock, level) = false
cacheable(block::Cache) = true
cacheable(cache_block::Cache{N, L}, level) where {N, L} =
    level > L && !(cache_block.block in keys(cache_block.cache))

# force cache this cache block
function cache!(cache_block::Cache)
    cache_block.cache[copy(cache_block.block)] =
        sparse(cache_block.block)
    cache_block
end

function cache!(cache_block::Cache{N, L, T, BT, TA}) where {N, L, T, BT <: PureBlock{N, T}, TA <: Matrix{T}}
    cache_block.cache[copy(cache_block.block)] =
        full(cache_block.block)
    cache_block
end

cache!(cache_block::Cache, level::Int) =
    (cacheable(cache_block, level) && cache!(cache_block); cache_block)

update!(block::Cache, params...) = update!(block.block, params...)

import Base: empty!
empty!(cache_block::Cache) = empty!(cache_block.cache)
empty!(cache_block::Cache, level::Int) =
    (cacheable(cache_block, level) || empty!(cache_block); cache_block)
