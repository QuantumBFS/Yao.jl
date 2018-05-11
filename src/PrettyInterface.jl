# blocks can only be constructed through factory methods

# 1. primitive blocks
# 1.1 constant gate

export gate
"""
    gate(type, gate_type)
    gate(gate_type)

Create an instance of `gate_type`.

### Example

create a Pauli X gate: `gate(X)`
"""
gate = Gate

# 1.2 phase gate
export phase
phase(::Type{T}, theta) where {T <: Real} = PhiGate{T}(theta)
phase(theta) = phase(Float64, theta)

# 1.3 rotation gate
export rot
rot(::Type{T}, ::Type{GT}, theta::T) where {T <: Real, GT} = RotationGate{GT, T}(theta)
rot(::Type{GT}, theta::T) where {GT, T <: Real} = rot(Float64, GT, theta)

# 2. composite blocks

# 2.1 chain block
export chain

function chain(blocks::PureBlock{N}...) where N
    ChainBlock(blocks...)
end

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
kron(total, blocks::Union{PureBlock, Tuple, Pair}...) = KronBlock(total, blocks)
kron(total, blocks) = KronBlock(total, blocks)
kron(blocks::Union{PureBlock, Tuple, Pair}...) = KronBlock(blocks)
kron(blocks) = KronBlock(blocks)

# 2.3 control block

export C

function C(controls::Int...)
    function _C(block_and_addr)
        total->ControlBlock(total, [controls...], block_and_addr...)
    end
end


# 3. measurement
export measure
measure(m::Int) = Measure{m}()

export measure_remove
measure_remove(m::Int) = MeasureAndRemove{m}()

# 4. others

# NOTE: use compose instead, this will only be a low level type
# 4.1 sequence
# export sequence
# sequence(blocks...) = Sequence([blocks...])

# 4.2 concentrator
export focus
focus(orders...) = Concentrator(orders...)


# all blocks are callable

# NOTE: this is a workaround in v0.6, multiple dispatch for call
#       is disabled in v0.6

for BLOCK in [
    # primitive
    Gate,
    PhiGate,
    RotationGate,
    # composite blocks
    ChainBlock,
    KronBlock,
    ControlBlock,
    # others
    Concentrator,
    Sequence,
    Measure,
] 
    @eval begin
        # 1. when input is register, call apply!
        (x::$BLOCK)(reg::Register) = apply!(reg, x)
        # 2. when input is a block, compose as function call
        (x::$BLOCK)(b::AbstractBlock) = reg->apply!(apply!(reg, b), x)
    end
end

# Abbreviations

# 1.Block with address

struct BlockWithAddr{BT <: AbstractBlock}
    block::BT
    addr::Int
end

# 1.Pauli Gates & Hadmard
export X, Y, Z, H

for (NAME, GTYPE) in [
    (:X, X),
    (:Y, Y),
    (:Z, Z),
    (:H, Hadmard)
]

@eval begin

    $NAME() = gate($GTYPE)

    function $NAME(addr::Int)
        (gate($GTYPE), addr)
    end

    function $NAME(r::UnitRange)
        (gate($GTYPE), r)
    end

    function $NAME(num_qubit::Int, addr::Int)
        kron(num_qubit, (1, gate(X)))
    end

    function $NAME(num_qubit::Int, r)
        kron(num_qubit, (i, gate($GTYPE)) for i in r)
    end

end

end
