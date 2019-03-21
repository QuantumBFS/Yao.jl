using YaoBase

export prewalk, postwalk, blockfilter!

"""
    prewalk(f, src::AbstractBlock)

Walk the tree and call `f` once the node is visited.
"""
function prewalk(f::Base.Callable, src::AbstractBlock)
    out = f(src)
    for each in subblocks(src)
        prewalk(f, each)
    end
    return out
end

"""
    postwalk(f, src::AbstractBlock)

Walk the tree and call `f` after the children are visited.
"""
function postwalk(f::Base.Callable, src::AbstractBlock)
    for each in subblocks(src)
        postwalk(f, each)
    end
    return f(src)
end

blockfilter!(f, v::Vector, blk::AbstractBlock) =
    postwalk(x -> f(x) ? push!(v, x) : v, blk)
