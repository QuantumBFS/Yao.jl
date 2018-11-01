"""
    IterControl{N, C}

N is the size of hilbert space, C is the number of shifts.
"""
struct IterControl{N, C}
    base::Int
    masks::SVector{C, Int}
    ks::SVector{C, Int}
end

function IterControl{N}(base::Int, masks, ks) where N
    C=length(ks)
    IterControl{N, C}(base, SVector{C, Int}(masks), SVector{C, Int}(ks))
end

function Base.iterate(ic::IterControl{N, C}, state = 0) where {N, C}
    if state == N
        nothing
    else
        res = state
        @simd for s in 1:C
            @inbounds res = lmove(res, ic.masks[s], ic.ks[s])
        end

        res+ic.base, state+1
    end
end

Base.length(ic::IterControl{N}) where N = N
Base.eltype(::Type{IterControl}) = Int
function Base.getindex(ic::IterControl{N, C}, i::Int) where {N, C}
    res = i-1
    for s in 1:C
        @inbounds res = lmove(res, ic.masks[s], ic.ks[s])
    end
    res+ic.base
end

lmove(b::Int, mask::Int, k::Int)::Int = (b&~mask)<<k + (b&mask)

"""
    itercontrol(num_bit::Int, poss::Vector{Int}, vals::Vector{Int}) -> IterControl

Return the iterator for basis with `poss` controlled to values `vals`, with the total number of bits `num_bit`.
"""
function itercontrol(num_bit::Int, poss::Vector{Int}, vals::Vector{Int})
    base = bmask(poss[vals.!=0]...)
    masks, ks = group_shift(num_bit, poss)
    IterControl{1<<(num_bit-length(poss))}(base, masks, ks)
end

function group_shift(num_bit::Int, poss::Vector{Int})
    poss |> sort!
    masks = Int[]
    ns = Int[]
    k_pre = -1
    for k in poss
        if k == k_pre+1
            ns[end] += 1
        else
            push!(masks, bmask(0:k-1))
            push!(ns, 1)
        end
        k_pre = k
    end
    masks, ns
end

"""
    controldo(func::Function, ic::IterControl{N, C})

Faster than `for i in ic ... end`.
"""
function controldo(func::Function, ic::IterControl{N, C}) where {N, C}
    for i in 0:N-1
        @simd for s in 1:C
            @inbounds i = lmove(i, ic.masks[s], ic.ks[s])
        end
        func(i+ic.base)
    end
end
