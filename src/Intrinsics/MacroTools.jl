"""
    AddressConflictError <: Exception

Address conflict error in Block Construction.
"""
struct AddressConflictError <: Exception
    msg::String
end

"""
    QubitMismatchError <: Exception

Qubit number mismatch error when applying a Block to a Register or concatenating Blocks.
"""
struct QubitMismatchError <: Exception
    msg::String
end

function _assert_addr_inbounds(n::Int, addrs::Vector{UnitRange{Int}})
    addrs = sort(addrs, by=x->x.start)
    (minimum(first(addrs)) > 0 && maximum(last(addrs)) <= n) || throw(AddressConflictError("addr out of bounds"))
    true
end

function _assert_addr_safe(n::Int, addrs::Vector{UnitRange{Int}})
    addrs = sort(addrs, by=x->x.start)
    (minimum(first(addrs)) > 0 && maximum(last(addrs)) <= n) || throw(AddressConflictError("addr out of bounds"))
    for (nxt, cur) in zip(addrs[2:end], addrs[1:end-1])
        nxt.start > cur.stop || throw(AddressConflictError("addr has collisions at $(nxt.start)"))
    end
    true
end

function _assert_addr_fit(n::Int, addrs::Vector{UnitRange{Int}})
    addrs = sort(addrs, by=x->x.start)
    (minimum(first(addrs)) > 0 && maximum(last(addrs)) <= n) || throw(AddressConflictError("addr out of bounds"))
    addrs |> first |> minimum == 1 || throw(AddressConflictError("addr not exact fit at 1"))
    for (nxt, cur) in zip(addrs[2:end], addrs[1:end-1])
        nxt.start == cur.stop+1 || throw(AddressConflictError("addr not exact fit at $(nxt.start)"))
    end
    addrs |> last |> maximum == n || throw(AddressConflictError("addr not exact fit at end"))
    true
end

macro assert_addr_safe(total, addrs)
    #quote
    #    _assert_addr_safe($total, $(esc(addrs)))
    #end
    :(_assert_addr_safe($total, $(esc(addrs))))
end

macro assert_addr_fit(total, addrs)
    quote
        _assert_addr_fit($total, $(esc(addrs)))
    end
end

macro assert_addr_inbounds(total, addrs)
    quote
        _assert_addr_inbounds($total, $(esc(addrs)))
    end
end
