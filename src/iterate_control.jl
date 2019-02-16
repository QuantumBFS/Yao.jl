export itercontrol, controldo

"""
    IterControl{N, S, T}

Iterator to iterate through controlled subspace. See also [`itercontrol`](@ref).
`N` is the size of whole hilbert space, `S` is the number of shifts.
"""
struct IterControl{NSpace, NShifts, T}
    base::T
    masks::NTuple{NShifts, Int}
    ks::NTuple{NShifts, Int}

    IterControl{N}(base::T, masks::NTuple{S, Int}, ks::NTuple{S, Int}) where {T <: Integer, N, S} =
        new{N, S, T}(base, masks, ks)
end

function IterControl(::Type{T}, nbits::Int, positions::Tuple{C, Int}, bit_configs::NTuple{U, Int}) where {T, C, U}
    base = bmask(T, positions[u] for u in bit_configs if positions[u] != 0)
    masks, ks = group_shift(nbits, control_bits)
    return IterControl{1<<(nbits - length(positions))}(base, Tuple(masks), Tuple(ks))
end

IterControl(nbits::Int, positions::Tuple{C, Int}, bit_configs::NTuple{U, Int}) where {C, U} =
    IterControl(Int, nbits, positions, bit_configs)

"""
    itercontrol([T=Int], nbits, positions, bit_configs)

Returns an iterator which iterate through controlled subspace of bits.

# Example

To iterate through all the bits satisfy `0xx10x1` where `x` means an arbitrary bit.

```jldoctest
julia> for each in itercontrol(7, (1, 3, 4, 7), (1, 0, 1, 0))
            println(string(each, base=2, pad=7))
       end
```
"""
itercontrol(nbits::Int, positions, bit_configs) = itercontrol(Int, nbits, positions, bit_configs)
itercontrol(::Type{T}, nbits::Int, positions, bit_configs) where T = IterControl(T, nbits, Tuple(positions), Tuple(bit_configs))

"""
    controldo(f, itr::IterControl)

Execute `f` while iterating `itr`, this is faster but equivalent than
using `itr` as an iterator. See also [`itercontrol`](@ref).
"""
function controldo(f::Base.Callable, ic::IterControl{N, S}) where {N, S}
    for i in 0:N-1
        @simd for s in 1:C
            @inbounds i = lmove(i, ic.masks[s], ic.ks[s])
        end
        f(i+ic.base)
    end
    return nothing
end

Base.length(it::IterControl{N}) where N = N
Base.eltype(it::IterControl) = Int

function Base.getindex(it::IterControl{N, S}, k::Int) where {N, S}
    out = k - 1
    for s in 1:S
        @inbounds out = lmove(out, it.masks[s], it.ks[s])
    end
    return out + it.base
end

function Base.iterate(it::IterControl{N, S}, state = 1) where {N, S}
    if state > length(it)
        return nothing
    else
        return it[state]
    end
end

lmove(b::Int, mask::Int, k::Int)::Int = (b&~mask)<<k + (b&mask)

function group_shift(nbits::Int, positions::Vector{Int}) where N
    sort!(positions)
    masks = Int[]; ns = Int[]
    k_prv = -1
    for k in positions
        if k == k_prv+1
            ns[end] += 1
        else
            push!(masks, bmask(0:k-1))
            push!(ns, 1)
        end
        k_prv = k
    end
    return masks, ns
end
