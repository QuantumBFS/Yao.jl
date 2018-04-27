#################
# Composite Blocks
#################
import Base: kron
export chain

struct ChainBlock{N, T <: AbstractBlock{N}} <: AbstractBlock{N}
    list::Vector{T}
end

ChainBlock(nqubit::Int, list::Vector) = ChainBlock{nqubit}(list)
ChainBlock(nqubit::Int, list) = ChainBlock(nqubit, [list...])

"""
    chain(blocks...) -> ChainBlock

Chain a list of blocks on N qubits together.
"""
chain(blocks::AbstractBlock{N}...) where N = ChainBlock(N, blocks)
full(::Type{T}, block::ChainBlock) where T = prod(x->full(T, x), block.list)
sparse(::Type{T}, block::ChainBlock) where T = prod(x->sparse(T, x), block.list)

function apply!(block::ChainBlock{N}, reg::Register{N, 1}) where N
    for each in block.list
        apply!(each, reg)
    end
    reg
end

# # TODO: create view for register
# function apply!(block::ChainBlock{N}, reg::Register{N, B}) where {N, B}
#     for i=1:B
#         each = view_batch(reg, i)
#         for each in block.list
#         end
#     end
# end

struct KronBlock{N} <: AbstractBlock{N}
    heads::Vector{Int}
    block_list::Vector
end

KronBlock(nqubit::Int, heads, list) = KronBlock(nqubit, heads, list)

function KronBlock(heads, list)
    @assert length(heads) == length(list) "block list length mismatch"
    nqubit = heads[end] + length(list[end])
    KronBlock(nqubit, [heads...], list)
end

"""
    KronBlock(list)

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
function KronBlock(blocks...) end

function KronBlock(list::NTuple)
    curr_head = 1
    heads = []
    blocks = []
    for each in list
        if isa(each, AbstractBlock)
            append!(heads, curr_head)
            curr_head += nqubit(each)
            append!(blocks, each)
        elseif isa(each, Tuple)
            curr_head, block = each
            append!(heads, curr_head)
            curr_head += nqubit(block)
            append!(blocks, block)
        end
    end
    KronBlock(heads, blocks)
end

"""
    kron(blocks...) -> KronBlock
    KronBlock(blocks...)

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
kron(blocks...) = KronBlock(blocks...)

full(::Type{T}, block::KronBlock) where T = full(sparse(T, block))
function sparse(::Type{T}, block::KronBlock{N}) where {T, N}
    curr_head = 1
    first_head = first(block.heads)
    first_block = first(block.block_list)
    op = if curr_head == first_head
        curr_head += nqubit(first_block)
        sparse(T, first_block)
    else
        kron(speye(T, first_head - curr_head), sparse(T, first_block))
        curr_head = first_head + nqubit(first_block)
    end

    count = 2
    while count != length(block.heads)
        next_head = block.heads[count]
        next_block = block.block_list[count]
        if curr_head != next_head
            op = kron(op, speye(T, next_head - curr_head))
            curr_head = next_head
        end
        op = kron(op, sparse(T, next_block))
        curr_head += nqubit(next_block)
        count+=1
    end

    if curr_head != N
        op = kron(op, speye(T, N - curr_head))
    end
    return op
end

function apply!(block::KronBlock{N}, reg::Register{N, 1, T}) where {N, T}
    reg.state = reshape(full(T, block) * statevec(reg), size(reg))
    reg
end

struct Concentrator{N, M, T <: AbstractBlock{M}} <: AbstractBlock{N}
    lines::NTuple{M, Int}
    block::T
end

Concentrator(nqubit::Int, block::T, lines::NTuple{M, Int}) where {M, T <: AbstractBlock{M}} =
    Concentrator{nqubit, M, T}(lines, block)
Concentrator(nqubit::Integer, block::AbstractBlock, lines::Int...) =
    Concentrator(nqubit, block, lines)

concentrate(nqubit::Int, block::AbstractBlock{M}, lines::NTuple{M, Int}) where M =
    Concentrator(nqubit, block, lines)
concentrate(nqubit::Integer, block::AbstractBlock, lines::Int...) =
    concentrate(nqubit, block, lines)
