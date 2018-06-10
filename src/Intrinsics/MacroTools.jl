function _assert_addr_safe(n::Int, addrs::Vector{UnitRange{Int}})
    _addrs = sort(addrs, by=x->x.start)
    maximum(last(_addrs)) <= n || throw(AssertionError("out of bounds"))

    flag = true
    for (nxt, cur) in zip(_addrs[2:end], _addrs[1:end-1])
        nxt.start > cur.stop || throw(AssertionError("addr has collisions at $(nxt.start)"))
    end
    true
end

macro assert_addr_safe(total::Int, addrs)
    quote
        _assert_addr_safe($total, $(esc(addrs)))
    end
end
