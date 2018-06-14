# This part declares factory functions for constructing composite blocks

function parse_block(n::Int, x::Function)
    x(n)
end

function parse_block(n::Int, x::MatrixBlock{N}) where N
    n == N || throw(ArgumentError("number of qubits does not match: $x"))
    x
end

# 2. composite blocks
# 2.1 chain block
export chain

"""
    chain([T], n::Int) -> ChainBlock
    chain([n], blocks) -> ChainBlock

Returns a `ChainBlock`. This factory method can be called lazily if you
missed the total number of qubits.

This chains several blocks with the same size together.
"""
function chain end
chain(::Type{T}, n::Int) where T = ChainBlock{n, T}([])
chain(n::Int) = chain(DefaultType, n)
chain() = n -> chain(n)

function chain(n::Int, blocks)
    if blocks isa Union{Function, MatrixBlock, Pair}
        ChainBlock([parse_block(n, blocks)])
    else
        ChainBlock(MatrixBlock{n}[parse_block(n, each) for each in blocks])
    end
end

chain(blocks) = n -> chain(n, blocks)

function chain(blocks::Vector{MatrixBlock{N}}) where N
    ChainBlock(Vector{MatrixBlock{N}}(blocks))
end

function chain(n, blocks...)
    ChainBlock(MatrixBlock{n}[parse_block(n, each) for each in blocks])
end

function chain(blocks::MatrixBlock{N}...) where N
    ChainBlock(collect(MatrixBlock{N}, blocks))
end

# 2.2 kron block
import Base: kron

"""
    kron([total::Int, ]block0::Pair, blocks::Union{MatrixBlock, Pair}...) -> KronBlock{total}

create a [`KronBlock`](@ref) with a list of blocks or tuple of heads and blocks.
If total is not provided, return a lazy constructor.

## Example
```@example
kron(4, 1=>X, 3=>Z, Y)
```
This will automatically generate a block list looks like
```
1 -- [X] --
2 ---------
3 -- [Z] --
4 -- [Y] --
```
"""
kron(total::Int, block0::Pair, blocks::Union{MatrixBlock, Pair}...) = KronBlock{total}((block0, blocks...))
function kron(total::Int, blocks::MatrixBlock...)
    sum(nqubits, blocks) == total || throw(AddressConflictError("Size of blocks does not match roller size."))
    KronBlock{total}(blocks)
end
kron(total::Int, g::Base.Generator) = KronBlock{total}(g)
# NOTE: this is ambiguous
kron(blocks::Union{MatrixBlock, Pair{Int, <:MatrixBlock}}...) = N->KronBlock{N}(blocks)
kron(blocks) = N->KronBlock{N}(blocks)

# 2.3 control block

export C, control

decode_sign(ctrls::Int...) = ctrls .|> abs, ctrls .|> sign .|> (x->(1+x)÷2)

"""
    control([total], controls, target) -> ControlBlock

Constructs a [`ControlBlock`](@ref)
"""
function control end

function control(total::Int, controls, target)
    ControlBlock{total}(decode_sign(controls...)..., target.second, target.first)
end

function control(controls, target)
    total->ControlBlock{total}(decode_sign(controls...)..., target.second, target.first)
end

function control(total::Int, controls)
    x::Pair->ControlBlock{total}(decode_sign(controls...)..., x.second, x.first)
end

function control(controls)
    function _control(x::Pair)
        total->ControlBlock{total}(decode_sign(controls...)..., x.second, x.first)
    end
end

function C(controls::Int...)
    function _C(x::Pair{I, BT}) where {I, BT <: MatrixBlock}
        total->ControlBlock{total}(decode_sign(controls...)..., x.second, x.first)
    end
end

# 2.4 roller

export roll, rollrepeat

"""
    rollrepeat([n::Int,] block::MatrixBlock) -> Roller{n}

Construct a [`Roller`](@ref) block, which is a faster than [`KronBlock`](@ref) to calculate
similar small blocks tile on the whole address.
"""
function rollrepeat end
rollrepeat(n::Int, block::MatrixBlock) = Roller{n}(block)
rollrepeat(block::MatrixBlock) = n->rollrepeat(n, block)

"""
    roll([n::Int,] block::MatrixBlock) -> Roller{n}

Construct a [`Roller`](@ref) block, which is a faster than [`KronBlock`](@ref) to calculate
similar small blocks tile on the whole address.
"""
function roll end

roll(blocks::MatrixBlock...) = n->Roller(blocks)
roll(n, blocks::MatrixBlock...) = Roller{n, blocks|>_blockpromote, typeof(blocks)}(blocks)

# 2.5 repeat

import Base: repeat

"""
    repeat([n::Int,] x::MatrixBlock, [addrs]) -> RepeatedBlock{n}

Construct a [`RepeatedBlock`](@ref), if n (the number of qubits) not supplied, using lazy evaluation.
If addrs not supplied, blocks will fill the qubit space.
"""
repeat(n::Int, x::MatrixBlock, addrs) = RepeatedBlock{n}(x, addrs)
repeat(n::Int, x::MatrixBlock) = RepeatedBlock{n}(x)
repeat(x::MatrixBlock, params...) = n->repeat(n, x, params...)

export concentrate

"""
    concentrate(nbit::Int, block::AbstractBlock, addrs::Vector{Int}) -> Concentrator{nbit}

concentrate blocks on serveral addrs.
"""
concentrate(nbit::Int, block::AbstractBlock, addrs::Vector{Int}) = Concentrator{nbit}(block, addrs)
