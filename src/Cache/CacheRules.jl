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

function cache(block::ChainBlock, ::Type{CT}, level::UInt; recursive::Bool=false) where CT
    if recursive
        chain = similar(block)
        for (i, each) in enumerate(block)
            chain[i] = cache(each, level, recursive=true)
        end
    else
        chain = block
    end

    cache!(global_cache(CT), chain, level)
    Cached(chain)
end

function cache(block::KronBlock, ::Type{CT}, level::UInt; recursive::Bool=false) where CT
    if recursive
        x = similar(block)
        for (k, v) in block
            x[k] = cache(v, level, recursive=true)
        end
    else
        x = block
    end

    cache!(global_cache(CT), x, level)
    Cached(x)
end

function cache(block::Roller{N, M, T}, ::Type{CT}, level::UInt; recursive::Bool=false) where {N, M, T, CT}
    if recursive
        roller = Roller{N, T}(ntuple(x->cache(block[x], level, recursive=true), Val(M))...)
    else
        roller = block
    end
    cache!(global_cache(CT), roller, level)
    Cached(roller)
end
