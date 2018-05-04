import DataStructures: SortedDict

promote_block_eltype(blocks) = promote_type([eltype(each) for each in blocks]...)

"""
    KronBlock{N, T} <: CompositeBlock{N, T}

composite block that combine blocks by kronecker product.
"""
struct KronBlock{N, T} <: CompositeBlock{N, T}
    kvstore::SortedDict{Int, PureBlock}
end

function KronBlock(total_bit_num::Int, kv::SortedDict)
    N = total_bit_num
    T = promote_block_eltype(values(kv))
    KronBlock{N, T}(kv)
end

_get_total_qubit_num(kv::SortedDict) = (key = maximum(keys(kv)); key + nqubit(kv[key]) - 1)

@inline function _parse_arg_for_kron_block(blocks)
    curr_head = 1
    kv = SortedDict{Int, PureBlock}()
    for each in blocks
        if isa(each, PureBlock)
            kv[curr_head] = each
            curr_head += nqubit(each)
        elseif isa(each, Union{Tuple, Pair}) # 2=>block/(2, block)
            curr_head, block = each
            kv[curr_head] = block
            curr_head += nqubit(block)
        else
            throw(ErrorException("KronBlock only takes PureBlock, TODO: custom error"))
        end
    end
    return kv
end

function KronBlock(total_bit_num, blocks)
    kv = _parse_arg_for_kron_block(blocks)
    KronBlock(total_bit_num, kv)
end

function KronBlock(blocks)
    kv = _parse_arg_for_kron_block(blocks)
    n = _get_total_qubit_num(kv)
    KronBlock(n, kv)
end

function copy(block::KronBlock{N, T}) where {N, T}
    kvstore = similar(block.kvstore)
    for (key, val) in block.kvstore
        # copy each, default `copy(::AbstractDict)`
        # won't copy its values.
        kvstore[key] = copy(val)
    end
    KronBlock{N, T}(kvstore)
end

import Base: kron

"""
    kron(blocks...) -> KronBlock
    kron(iterator) -> KronBlock
    kron(total, blocks...) -> KronBlock
    kron(total, iterator) -> KronBlock

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
kron(total, blocks::Union{PureBlock, Tuple, Pair}...) = KronBlock(total, blocks)
kron(total, blocks) = KronBlock(total, blocks)
kron(blocks::Union{PureBlock, Tuple, Pair}...) = KronBlock(blocks)
kron(blocks) = KronBlock(blocks)

# some useful sugar
import Base: getindex, setindex!, keys, values

keys(blocks::KronBlock) = keys(blocks.kvstore)
values(blocks::KronBlock) = values(blocks.kvstore)
getindex(block::KronBlock, key) = getindex(block.kvstore, key)
# NOTE: we do not allow insertion into KronBlock besides `kron`
# setindex!(block::KronBlock, v::PureBlock, key) = setindex!(block.kvstore, v, key)

# kronecker can take non-unitary operators
# we check whether it is unitary by checking
# each element.
isunitary(block::KronBlock) = all(isunitary, values(block))
iterate_blocks(c::KronBlock) = values(c)

#########################
# KronBlock: matrix form
#########################

full(block::KronBlock) = full(sparse(block))

@inline function sparse(block::KronBlock{N, T}) where {N, T}
    curr_addr = 1
    first_head_addr, first_block = first(block.kvstore)
    if curr_addr == first_head_addr
        curr_addr += nqubit(first_block)
        op = sparse(first_block)
    else
        op = kron(speye(T, 1<<(first_head_addr - curr_addr)), sparse(first_block))
        curr_addr = first_head_addr + nqubit(first_block)
    end

    heads = collect(keys(block.kvstore))
    blocks = collect(values(block.kvstore))
    for count = 2:length(heads)
        next_head = heads[count]
        next_block = blocks[count]
        if curr_addr != next_head
            op = kron(op, speye(T, 1<<(next_head - curr_addr)))
            curr_addr = next_head
        end
        op = kron(op, sparse(next_block))
        curr_addr += nqubit(next_block)
    end

    if curr_addr <= N
        op = kron(op, speye(T, 1<<(N - curr_addr + 1)))
    end
    return op
end

####################
# KronBlock: apply!
####################

(block::KronBlock)(reg::Register) = apply!(reg, block)
apply!(reg::Register, block::KronBlock) = (reg.state .= full(block) * state(reg); reg)

####################
# KronBlock: update!
####################

function dispatch!(block::KronBlock, params...)
    for each in params
        key, param = each
        dispatch!(block[key], param...)
    end
    block
end

function show(io::IO, block::KronBlock{N, T}) where {N, T}
    println(io, "KronBlock{$N, $T}")
    join(io, ["    " * "$key: $val" for (key, val) in block.kvstore], "\n")
end
