export cache


# method for initialization
# NOTE: this will cause an error if level is not actually unsigned
cache(block::MatrixBlock, level::Int=1; recursive::Bool=false) = cache(block, UInt(level), recursive=recursive)
cache(block::MatrixBlock, level::UInt; recursive::Bool=false) = cache(block, cache_type(block), level, recursive=recursive)

# only composite block can cache recursively
function cache(block::MatrixBlock, ::Type{CT}, level::UInt; recursive::Bool=false) where CT
    cache!(global_cache(CT), block, level)
    Cached(block)
end

function cache(block::CompositeBlock, ::Type{CT}, level::UInt; recursive::Bool=false) where CT
    if recursive
        map!(x->cache(x, level, recursive=recursive), block, block)
    end

    cache!(global_cache(CT), block, level)
    Cached(block)
end

function cache(block::ChainBlock, ::Type{CT}, level::UInt; recursive::Bool=false) where CT
    if recursive
        for (i, each) in enumerate(block)
            block[i] = cache(each, level, recursive=true)
        end
    end
    cache!(global_cache(CT), block, level)
    Cached(block)
end

function cache(block::KronBlock, ::Type{CT}, level::UInt; recursive::Bool=false) where CT
    if recursive
        for (k, v) in block
            block[k] = cache(v, level, recursive=true)
        end
    end

    cache!(global_cache(CT), block, level)
    Cached(block)
end
