export CacheFragment

struct CacheFragment{BT, K, MT}
    ref::BT
    storage::Dict{K, MT}

    function CacheFragment{BT, K}(x::BT) where BT where K
        new{BT, K, cache_type(BT)}(x, Dict{K, cache_type(BT)}())
    end

    function CacheFragment(x::BT) where BT
        CacheFragment{BT, BT}(x)
    end
end

cache_type(x) = Any
iscached(frag::CacheFragment{BT, BT, MT}) where {BT, MT} = frag.ref in keys(frag.storage)

# default update rule
function update!(frag::CacheFragment{BT, BT, MT}, val) where {BT, MT}
    if !iscached(frag)
        frag.storage[frag.ref] = val
    end
    frag
end

function iscached(frag::CacheFragment)
    frag.ref in keys(frag.storage)
end

pull(frag::CacheFragment{BT, BT, MT}) where {BT, MT} = frag.storage[frag.ref]
clear!(frag::CacheFragment) = (empty!(frag.storage); frag)
