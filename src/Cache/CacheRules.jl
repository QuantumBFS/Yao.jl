export cache

"""
    cache(block, level; recursive=false) -> Cached

initialize cache for this block with cache level
"""
function cache end

# method for initialization
# NOTE: this will cause an error if level is not actually unsigned
cache(block::PureBlock, level::Int=1; recursive::Bool=false) = cache(block, UInt(level), recursive=recursive)
cache(block::PureBlock, level::UInt; recursive::Bool=false) = cache(block, cache_type(block), level, recursive=recursive)

# only composite block can cache recursively
function cache(block::PureBlock, ::Type{CT}, level::UInt; recursive::Bool=false) where CT
    cache!(global_cache(CT), block, level)
    Cached(block)
end

function cache(chain::ChainBlock{N, T}, ::Type{CT}, level::UInt; recursive::Bool=false) where {N, T, CT}
    block = chain

    if recursive
        block = ChainBlock(N, ntuple(x->cache(x, level, recursive=recursive), chain.blocks))
    end

    cache!(global_cache(CT), block, level)
    Cached(block)
end

function cache(block::KronBlock, ::Type{CT}, level::UInt; recursive::Bool=false) where CT

    if recursive
        for (line, subblock) in block.kvstore
            block.kvstore[line] = cache(subblock, level, recursive=recursive)
        end
    end

    cache!(global_cache(CT), block, level)
    Cached(block)
end

function cache(ctrl::ControlBlock{BT, N, T}, ::Type{CT}, level::UInt; recursive::Bool=false) where {BT, N, T, CT}

    block = ctrl
    if recursive
        ctrl_block = cache(ctrl.block, level, recursive=recursive)
        block = ControlBlock{BT, N, T}(ctrl.control, ctrl_block, ctrl.pos)
    end

    cache!(global_cache(CT), block, level)
    Cached(block)
end
