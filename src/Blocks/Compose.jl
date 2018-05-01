####################
# Composite Blocks
####################
# There are two composite blocks:
# 1. ChainBlock, chain a list of blocks with same size together
# 2. KronBlock, combine several blocks by kronecker product

promote_block_eltype(blocks) = promote_type([eltype(each) for each in blocks]...)

struct ChainBlock{N, T} <: PureBlock{N, T}
    list::Vector
end

ChainBlock(nqubit, blocks::Vector) = ChainBlock{nqubit, promote_block_eltype(blocks)}(blocks)
ChainBlock(nqubit, blocks) = ChainBlock(nqubit, [blocks...])

export chain

function chain(blocks...)
    N = ninput(first(blocks))
    for (prev, next) in zip(blocks[1:end-1], blocks[2:end])
        @assert noutput(prev) == ninput(next) "shape mismatch"
    end
    @assert N == noutput(blocks[end]) "Chain block requires the same input and output size"
    ChainBlock(N, blocks)
end

function apply!(reg::Register{N}, block::ChainBlock{N}) where N
    for each in block.list
        apply!(reg, each)
    end
    reg
end

function update!(block::ChainBlock, params...)
    for each in params
        index, param = params
        update!(block.list[index], param...)
    end
end

function cache!(block::ChainBlock; level=1, force=false)
    for each in block.list
        cache!(each, level=level, force=force)
    end
    block
end

# TODO: provide matrix form when there are Concentrators
full(block::ChainBlock) = prod(x->full(x), block.list)
sparse(block::ChainBlock) = prod(x->sparse, block.list)
copy(block::ChainBlock{N, T}) where {N, T} = ChainBlock{N, T}([copy(each) for each in block.list])

struct KronBlock{N, T} <: PureBlock{N, T}
    heads::Vector{Int}
    list::Vector
end

KronBlock(nqubit::Int, heads, blocks) = KronBlock{nqubit, promote_block_eltype(blocks)}(heads, blocks)

function KronBlock(heads, list)
    @assert length(heads) == length(list) "block list length mismatch"
    nqubit = heads[end] + length(list[end])
    KronBlock(nqubit, [heads...], [list...])
end

function KronBlock(blocks)
    curr_head = 1
    heads = []
    blocks = []
    for each in list
        if isa(each, PureBlock)
            append!(heads, curr_head)
            curr_head += nqubit(each)
            append!(blocks, each)
        elseif isa(each, Tuple)
            curr_head, block = each
            append!(heads, curr_head)
            curr_head += nqubit(block)
            append!(blocks, block)
        else
            throw(ErrorException("KronBlock only takes PureBlock, TODO: custom error"))
        end
    end
    KronBlock(heads, blocks)
end

import Base: kron

"""
    kron(blocks...) -> KronBlock
create a `KronBlock` with a list of blocks or tuple of heads and blocks.

## Example
```julia
block1 = Gate(X)
block2 = Gate(Z)
block3 = Gate(Y)
KronBlock(block1, (3, block2), block3)
```
This will automatically generate a block list looks like
```
1 -- [X] --
2 ---------
3 -- [Z] --
4 -- [Y] --
```
"""
kron(blocks...) = KronBlock(blocks)

full(block::KronBlock) = full(sprase(block))

@inline function sparse(block::KronBlock{N, T}) where {N, T}
    curr_head = 1
    first_head = first(block.heads)
    first_block = first(block.list)
    op = if curr_head == first_head
        curr_head += nqubit(first_block)
        sparse(first_block)
    else
        kron(speye(T, first_head - curr_head), sparse(first_block))
        curr_head = first_head + nqubit(first_block)
    end

    count = 2
    while count != length(block.heads)
        next_head = block.heads[count]
        next_block = block.list[count]
        if curr_head != next_head
            op = kron(op, speye(T, next_head - curr_head))
            curr_head = next_head
        end
        op = kron(op, sparse(next_block))
        curr_head += nqubit(next_block)
        count += 1
    end

    if curr_head != N
        op = kron(op, speye(T, N - curr_head))
    end
    return op
end

copy(block::KronBlock{N, T}) where {N, T} =
    KronBlock{N, T}(copy(block.heads), [copy(each) for each in block.list])

apply!(reg::Register{N}, block::KronBlock{N}) where N = (reg.state .= full(block) * state(reg); reg)

function update!(block::KronBlock, params...)
    for each in params
        index, param = each
        update!(block.list[index], param...)
    end
    block
end

function cache!(block::KronBlock; level::Int=1, force::Bool=false)
    for each in block.list
        cache!(each; level=level, force=force)
    end
    block
end