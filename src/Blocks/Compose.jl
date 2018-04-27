#################
# Compose Blocks
#################
import Base: kron
export chain

struct ChainBlock{N, T <: AbstractBlock{N}} <: AbstractBlock{N}
    list::Vector{T}
end

ChainBlock(nqubit::Int, list) = ChainBlock{nqubit}([list...])

"""
    chain(blocks...) -> ChainBlock

Chain a list of blocks on N qubits together.
"""
chain(blocks::AbstractBlock{N}...) where N = ChainBlock(N, blocks)

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
