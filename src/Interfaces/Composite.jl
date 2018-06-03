# 2. composite blocks
# 2.1 chain block
export chain

function chain(blocks::Vector)
    ChainBlock(blocks)
end

function chain(blocks::MatrixBlock{N}...) where N
    ChainBlock(blocks...)
end

Base.getindex(::typeof(chain), xs...) = ChainBlock(xs...)

# 2.2 kron block
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
kron(total::Int, blocks::Union{MatrixBlock, Tuple, Pair}...) = KronBlock{total}(blocks)
kron(total::Int, g::Base.Generator) = KronBlock{total}(g)
# NOTE: this is ambiguous
# kron(total::Int, blocks) = KronBlock{total}(blocks)
kron(blocks::Union{MatrixBlock, Tuple{Int, <:MatrixBlock}, Pair{Int, <:MatrixBlock}}...) = N->KronBlock{N}(blocks)
kron(blocks) = N->KronBlock{N}(blocks)

# 2.3 control block

export C, control

function control(total::Int, controls, block, addr)
    ControlBlock{total}([controls...], block, addr)
end

function control(controls, block, addr)
    ControlBlock([controls...], block, addr)
end

# function control(total::Int, controls)
#     x::RangedBlock->ControlBlock{total}([controls...], x.block, x.range)
# end

# function control(controls)
#     x::RangedBlock->ControlBlock([controls...], x.block, x.range)
# end

# function C(controls::Int...)
#     function _C(x::RangedBlock{BT, Int}) where BT
#         total->ControlBlock{total}([controls...], x.block, x.range)
#     end
# end

# 2.4 roller

export roll

roll(n::Int, block::MatrixBlock) = Roller{n}(block)

function roll(blocks::MatrixBlock...)
    T = promote_type([datatype(each) for each in blocks]...)
    N = sum(x->nqubits(x), blocks)
    Roller{N, T}(blocks)
end

roll(block::MatrixBlock) = n->roll(n, block)
