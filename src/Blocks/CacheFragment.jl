export CacheFragment

struct CacheFragment{BT, K, MT}
    ref::BT
    storage::Dict{K, MT}

    function CacheFragment{BT, K, MT}(x::BT) where {BT, K, MT}
        new{BT, K, MT}(x, Dict{K, MT}())
    end

    function CacheFragment{BT, K}(x::BT) where BT where K
        new{BT, K, cache_type(BT)}(x, Dict{K, cache_type(BT)}())
    end

    function CacheFragment(x::BT) where BT
        CacheFragment{BT, typeof(cache_key(x))}(x)
    end
end

# default update rule
function update!(frag::CacheFragment, val)
    if !iscached(frag)
        frag.storage[cache_key(frag.ref)] = val
    end
    frag
end

function iscached(frag::CacheFragment)
    cache_key(frag.ref) in keys(frag.storage)
end

pull(frag::CacheFragment) = frag.storage[cache_key(frag.ref)]
clear!(frag::CacheFragment) = (empty!(frag.storage); frag)
