# forward content properties
cache_key(tb::TagBlock) = cache_key(content(tb))
occupied_locs(x::TagBlock) = occupied_locs(content(x))

Base.:(==)(a::TB, b::TB) where {TB<:TagBlock} = content(a) == content(b)
