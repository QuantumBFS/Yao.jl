"""
    SKronBlock

Static KronBlock:

`N`: total number of qubits
`T`: element type
`M`: total number of occupied qubits
`BT`: a sequence of certain block type

Static KronBlock allow us to collect more information in compile time
and we can then dispatch certain optimized methods to some patterns. It
is immutable like Static Array. This will lose some convinience but it
improves performance sometimes.
"""
struct SKronBlock{N, T, M, BT <: Tuple} <: CompositeBlock{N, T}
    slots::NTuple{N, UInt}
    addrs::NTuple{M, Int}
    blocks::BT

    function SKronBlock{N, T}(addrs::NTuple{M, Int}, blocks::BT) where {N, M, T, BT <: Tuple}
        slots = zeros(UInt, N)
        for (i, each) in enumerate(addrs)
            slots[each] = i
        end
        new{N, T, M, BT}(Tuple(slots), addrs, blocks)
    end
end

function SKronBlock(total::Int, addrs::Vector{Int}, blocks::Vector)
    N = total
    T = promote_type([eltype(each) for each in blocks]...)
    perm = sortperm(addrs)
    permute!(addrs, perm)
    permute!(blocks, perm)

    addrs = Tuple(addrs)
    blocks = Tuple(blocks)
    SKronBlock{N, T}(addrs, blocks)
end

function SKronBlock(total::Int, blocks)
    curr_head = 1
    block_list = []
    addrs = Int[]

    for each in blocks
        if isa(each, MatrixBlock)
            push!(block_list, each)
            push!(addrs, curr_head)
            curr_head += nqubit(each)
        elseif isa(each, Union{Tuple, Pair})
            curr_head, block = each
            push!(addrs, curr_head)
            push!(block_list, each)
            curr_head += nqubit(block)
        else
            throw(ErrorException("KronBlock only takes MatrixBlock"))
        end
    end

    SKronBlock(total, addrs, block_list)
end

function getindex(s::SKronBlock, index::Int)
    s.slots[index] == 0 && throw(ErrorException("this line is empty"))
    s.blocks[s.slots[index]]
end

function copy(block::SKronBlock{N, T, M, BT}) where {N, T, M, BT}
end
