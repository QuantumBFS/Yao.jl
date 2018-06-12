function _assert_addr_inbounds(n::Int, addrs::Vector{UnitRange{Int}})
    addrs = sort(addrs, by=x->x.start)
    (minimum(first(addrs)) > 0 && maximum(last(addrs)) <= n) || throw(AssertionError("out of bounds"))
    addrs
end

function _assert_addr_safe(n::Int, addrs::Vector{UnitRange{Int}})
    addrs = _assert_addr_inbounds(n ,addrs)
    for (nxt, cur) in zip(addrs[2:end], addrs[1:end-1])
        nxt.start > cur.stop || throw(AssertionError("addr has collisions at $(nxt.start)"))
    end
    true
end

function _assert_addr_fit(n::Int, addrs::Vector{UnitRange{Int}})
    addrs |> first |> minimum == 1 || throw(AssertionError("addr not exact fit at 1"))
    for (nxt, cur) in zip(addrs[2:end], addrs[1:end-1])
        nxt.start != cur.stop+1 || throw(AssertionError("addr not exact fit at $(nxt.start)"))
    end
    addrs |> last |> maximum == n || throw(AssertionError("addr not exact fit at end"))
    true
end

macro assert_addr_safe(total::Int, addrs)
    quote
        _assert_addr_safe($total, $(esc(addrs)))
    end
end

macro assert_addr_fit(total::Int, addrs)
    quote
        _assert_addr_fit($total, $(esc(addrs)))
    end
end

macro assert_addr_inbounds(total::Int, addrs)
    quote
        _assert_addr_inbounds($total, $(esc(addrs)))
    end
end
