using StaticArrays
export itercontrol, controldo

# NOTE: use SortedVector in Blocks would help benchmarks

"""
    IterControl{N, S, T}

Iterator to iterate through controlled subspace. See also [`itercontrol`](@ref).
`N` is the size of whole hilbert space, `S` is the number of shifts.
"""
struct IterControl{N, NShift, T}
    base::T
    masks::SVector{NShift, Int}
    ks::SVector{NShift, Int}

    function IterControl{N}(base::T, masks, ks) where {N, T}
        NShift = length(masks)
        new{N, NShift, T}(base, SVector{NShift, Int}(masks), SVector{NShift, Int}(ks))
    end
end

# NOTE: positions should be vector (MVector is the best), since it need to be sorted
#       do not use Tuple, or other immutables, it increases the sorting time.
function IterControl(::Type{T}, nbits::Int, positions::AbstractVector, bit_configs) where T
    base = bmask(T, positions[i] for (i, u) in enumerate(bit_configs) if u != 0)
    masks, ks = group_shift!(nbits, positions)
    return IterControl{1<<(nbits - length(positions))}(base, masks, ks)
end

IterControl(nbits::Int, positions::AbstractVector, bit_configs) =
    IterControl(Int, nbits, positions, bit_configs)

"""
    itercontrol([T=Int], nbits, positions, bit_configs)

Returns an iterator which iterate through controlled subspace of bits.

# Example

To iterate through all the bits satisfy `0xx10x1` where `x` means an arbitrary bit.

```jldoctest
julia> for each in itercontrol(7, [1, 3, 4, 7], (1, 0, 1, 0))
            println(string(each, base=2, pad=7))
       end
```
"""
itercontrol(nbits::Int, positions::AbstractVector, bit_configs) = itercontrol(Int, nbits, positions, bit_configs)
itercontrol(::Type{T}, nbits::Int, positions::AbstractVector, bit_configs) where T = IterControl(T, nbits, positions, bit_configs)

"""
    controldo(f, itr::IterControl)

Execute `f` while iterating `itr`, this is faster but equivalent than
using `itr` as an iterator. See also [`itercontrol`](@ref).
"""
function controldo(f::Base.Callable, ic::IterControl{N, S}) where {N, S}
    for i in 0:N-1
        @simd for s in 1:S
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
    @simd for s in 1:S
        @inbounds out = lmove(out, it.masks[s], it.ks[s])
    end
    return out + it.base
end

function Base.iterate(it::IterControl{N, S}, state = 1) where {N, S}
    if state > length(it)
        return nothing
    else
        return it[state], state + 1
    end
end

lmove(b::Int, mask::Int, k::Int)::Int = (b&~mask)<<k + (b&mask)

function group_shift!(nbits::Int, positions::AbstractVector{Int}) where N
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
