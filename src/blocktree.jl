# empty by default
subblock(blk::AbstractBlock) = ()

function blockwalk(f::Base.Callable, src::AbstractBlock; with=(parent, child, ret)->nothing)
    for each in subblock(blk)
        with(src, each, blockwalk(f, each))
    end
    return f(src)
end

@deprecate blockfilter!(f, v::Vector, blk::AbstractBlock) blockwalk(x -> f(x) ? push!(v, x) : v, blk)
