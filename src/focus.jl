using YaoBase, TupleTools

export focus!,
    relax!,
    partial_tr,
    exchange_sysenv


"""
    contiguous_shape_orders(shape, orders)

Merge the shape and orders if the orders are contiguous. Returns the
new merged shape and order.

# Example

```jldoctest; setup=:(using YaoArrayRegister)
julia> YaoArrayRegister.contiguous_shape_orders((2, 3, 4), (1, 2, 3))
([24], [1])
```
"""
function contiguous_shape_orders(shape, orders)
    new_shape, new_orders = Int[], Int[]
    prv = -1
    for cur in orders
        if cur == prv + 1
            new_shape[end] *= shape[cur]
        else
            push!(new_orders, cur)
            push!(new_shape, shape[cur])
        end
        prv = cur
    end
    # NOTE: some of the orders are merged above
    #       we use sortperm to retrieve correct
    #       orders
    inv_orders = sortperm(new_orders)
    return new_shape[inv_orders], invperm(inv_orders)
end

# NOTE: don't use Vector for move_ahead, it's way slower!
# Before:
# julia> @benchmark move_ahead($c, $o)
# BenchmarkTools.Trial:
#   memory estimate:  14.87 KiB
#   allocs estimate:  392
#   --------------
#   minimum time:     29.062 μs (0.00% GC)
#   median time:      31.316 μs (0.00% GC)
#   mean time:        39.724 μs (14.37% GC)
#   maximum time:     39.013 ms (99.86% GC)
#   --------------
#   samples:          10000
#   evals/sample:     1
# After:
# julia> @benchmark move_ahead($c, $o)
# BenchmarkTools.Trial:
#   memory estimate:  4.04 KiB
#   allocs estimate:  24
#   --------------
#   minimum time:     2.848 μs (0.00% GC)
#   median time:      3.045 μs (0.00% GC)
#   mean time:        4.013 μs (18.20% GC)
#   maximum time:     4.494 ms (99.86% GC)
#   --------------
#   samples:          10000
#   evals/sample:     9

"""
    move_ahead(collection, orders)

Move `orders` to the beginning of `collection`.
"""
move_ahead(collection, orders) = (orders..., setdiff(collection, orders)...)
move_ahead(ndim::Int, orders) = (orders..., setdiff(1:ndim, orders)...)

function group_permutedims(A::AbstractArray, orders)
    @assert length(orders) == ndims(A) "number of orders does not match number of dimensions"
    return unsafe_group_permutedims(A, orders)
end

# forward directly if the length is the same with ndims
function group_permutedims(A::AbstractArray{T, N}, orders::NTuple{N, Int}) where {T, N}
    return unsafe_group_permutedims(A, orders)
end

function unsafe_group_permutedims(A::AbstractArray, orders)
    s, o = contiguous_shape_orders(size(A), orders)
    return permutedims(reshape(A, s...), o)
end

"""
    is_order_same(locs) -> Bool

Check if the order specified by `locs` is the same as current order.
"""
is_order_same(locs) = all(a == b for (a, b) in zip(locs, 1:length(locs)))

# NOTE: locations is not the same with orders
# locations: some location of the wire
# orders: includes all the location of the wire in some order
function YaoBase.focus!(r::ArrayReg{B}, locs) where B
    if is_order_same(locs)
        arr = r.state
    else
        new_orders = move_ahead(nactive(r) + 1, locs)
        arr = group_permutedims(hypercubic(r), new_orders)
    end
    r.state = reshape(arr, 1 << length(locs), :)
    return r
end

function YaoBase.relax!(r::ArrayReg{B}, locs; to_nactive::Int=nqubits(r)) where B
    r.state = reshape(state(r), 1 << to_nactive, :)
    if !is_order_same(locs)
        new_orders = TupleTools.invperm(move_ahead(to_nactive+1, locs))
        r.state = reshape(group_permutedims(hypercubic(r), new_orders), 1 << to_nactive, :)
    end
    return r
end

function YaoBase.partial_tr(r::ArrayReg{B}, locs) where B
    orders = setdiff(1:nqubits(r), locs)
    focus!(r, orders)
    state = sum(rank3(r); dims=2)
    relax!(r, orders)
    return normalize!(ArrayReg(state))
end

"""
    exchange_sysenv(reg::ArrayReg) -> ArrayReg

Exchange system (focused qubits) and environment (remaining qubits).
"""
function exchange_sysenv(reg::ArrayReg{B}) where B
    ArrayReg{B}(reshape(permutedims(rank3(reg), (2,1,3)), :,size(reg.state, 1)*B))
end
