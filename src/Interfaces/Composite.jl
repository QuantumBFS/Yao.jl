# 2. composite blocks
# 2.1 chain block
export chain

chain(n::Int) = ChainBlock(MatrixBlock{n}[])
chain() = n -> chain(n)

function chain(n, blocks)
    _2block(x::Function) = x(n)
    _2block(x::MatrixBlock) = x

    if blocks isa Union{Function, MatrixBlock}
        ChainBlock([_2block(blocks)])
    else
        ChainBlock(MatrixBlock{n}[_2block(each) for each in blocks])
    end
end

chain(blocks) = n -> chain(n, blocks)

function chain(blocks::Vector{MatrixBlock{N}}) where N
    ChainBlock(Vector{MatrixBlock{N}}(blocks))
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

function control(total::Int, controls, target)
    ControlBlock{total}([controls...], target)
end

function control(controls, target)
    total->ControlBlock{total}([controls...], target)
end

function control(total::Int, controls)
    x::Pair->ControlBlock{total}([controls...], x)
end

function control(controls)
    function _control(x::Pair)
        total->ControlBlock{total}([controls...], x)
    end
end

function C(controls::Int...)
    function _C(x::Pair{I, BT}) where {I, BT <: MatrixBlock}
        total->ControlBlock{total}([controls...], x)
    end
end

# 2.4 roller

export roll

roll(n::Int, block::MatrixBlock) = Roller{n}(block)

function roll(N::Int, blocks::MatrixBlock...)
    T = promote_type([datatype(each) for each in blocks]...)
    @assert N >= sum(x->nqubits(x), blocks) "total number of qubits is not enough"
    Roller{N, T}(blocks)
end

roll(blocks::MatrixBlock...) = n->roll(n, blocks...)
