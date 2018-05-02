abstract type AbstractCache end

struct Cache{K, V}
    kvstore::Dict{K, V}
end


