export assert_addr_fit, assert_addr_inbounds, assert_addr_safe


macro assert_addrs(n, addrs, msgs...)
    msg = isempty(msgs) ? ex : msgs[1]
    if msg isa AbstractString
        msg = msg # pass-through
    elseif !isempty(msgs) && (isa(msg, Expr) || isa(msg, Symbol))
        # message is an expression needing evaluating
        msg = :(Main.Base.string($(esc(msg))))
    elseif isdefined(Main, :Base) && isdefined(Main.Base, :string) && applicable(Main.Base.string, msg)
        msg = Main.Base.string(msg)
    else
        # string() might not be defined during bootstrap
        msg = :(Main.Base.string($(Expr(:quote,msg))))
    end

    quote
        if length(addrs) == 0
            nothing
        else
            addrs = sort(addrs, by=x->x.start)
        end
    end
end

for METHOD in [:assert_addr_inbounds, :assert_addr_safe, :assert_addr_fit]
    @eval $METHOD(n::Int, addrs::Vector{<:Integer}) = $METHOD(n, UnitRange{Int}[i:i for i in addrs])
end

function assert_addr_inbounds(n::Int, addrs::Vector{UnitRange{Int}})
    if length(addrs) == 0 return true end
    addrs = sort(addrs, by=x->x.start)
    (minimum(first(addrs)) > 0 && maximum(last(addrs)) <= n) || throw(AddressConflictError("addr out of bounds"))
    true
end

function assert_addr_safe(n::Int, addrs::Vector{UnitRange{Int}})
    if length(addrs) == 0 return true end
    addrs = sort(addrs, by=x->x.start)
    (minimum(first(addrs)) > 0 && maximum(last(addrs)) <= n) || throw(AddressConflictError("addr out of bounds"))
    for (nxt, cur) in zip(addrs[2:end], addrs[1:end-1])
        nxt.start > cur.stop || throw(AddressConflictError("addr has collisions at $(nxt.start)"))
    end
    true
end

function assert_addr_fit(n::Int, addrs::Vector{UnitRange{Int}})
    if length(addrs) == 0 return n == 0 end
    addrs = sort(addrs, by=x->x.start)
    (minimum(first(addrs)) > 0 && maximum(last(addrs)) <= n) || throw(AddressConflictError("addr out of bounds"))
    addrs |> first |> minimum == 1 || throw(AddressConflictError("addr not exact fit at 1"))
    for (nxt, cur) in zip(addrs[2:end], addrs[1:end-1])
        nxt.start == cur.stop+1 || throw(AddressConflictError("addr not exact fit at $(nxt.start)"))
    end
    addrs |> last |> maximum == n || throw(AddressConflictError("addr not exact fit at end"))
    true
end

@which @assert 1==1
