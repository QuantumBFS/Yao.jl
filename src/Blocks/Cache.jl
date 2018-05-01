const MAX_CACHE_NUM = 10

struct Cache{N, L, BT <: PureBlock{N}, TA <: SparseMatrixCSC, T} <: AbstractCache{N, L, T}
    block::BT
    cache::Dict{BT, TA}
end

Cache(block::PureBlock{N}, level::Int) where N =
    Cache{N, level, typeof(block), SparseMatrixCSC{eltype(block), Int}, eltype(block)}(block, Dict())

export cache
cache(block::PureBlock; level::Int=1) = Cache(block, level)

function apply!(reg::Register, block::Cache)
    if block.block in block.cache
        reg.state .= block.cache[block.block] * state(reg)
    else
        apply!(reg, block.block)
        block.cache[copy(reg)] = sparse(block.block)
    end
    reg
end

cache!(block; level=1, force=false) = block

function cache!(block::Cache{N, L}; level=1, force=false) where {N, L}
    if force || (!(block.block in block.cache) && level > L)
        block.cache[copy(reg)] = sparse(block.block)
    end
    block
end

update!(block::Cache, params...) = update!(block.block, params...)
