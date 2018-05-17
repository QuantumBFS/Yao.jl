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
    slots::NTuple{N, UInt8}
    addrs::NTuple{M, Int}
    blocks::BT

    function SKronBlock{N, T}(blocks::MatrixBlock...) where N where T
        new{N, T}(zeros(UInt8, N), )
    end
end

function SKronBlock(total::Int, addrs::Vector{UInt}, blocks::Vector)
    N = total
    T = promote_type([eltype(each) for each in blocks]...)
    SKronBlock{N, T}(addrs, blocks)
end

function SKronBlock(total::Int, blocks)
    curr_addr = 1
    addrs = UInt[]
    blocks = []

    for each in blocks # blocks can be any iterable
        if isa(each, MatrixBlock)
            # a single block
            push!(addrs, curr_addr)
            push!(blocks, each)
            curr_addr += nqubit(each)
        elseif isa(each, Union{Tuple, Pair})
            # support 2=>block / (2, block)
            curr_addr, block = each
            push!(addrs, curr_head)
            push!()
        end
    end
end
