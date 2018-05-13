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

function chain(blocks::MatrixBlock{N}...) where N
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
kron(total, blocks::Union{MatrixBlock, Tuple, Pair}...) = KronBlock(total, blocks)
kron(total, blocks) = KronBlock(total, blocks)
kron(blocks::Union{MatrixBlock, Tuple, Pair}...) = KronBlock(blocks)
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

# 1.Pauli Gates & Hadmard
export X, Y, Z, H

for NAME in [:X, :Y, :Z, :H]

    GT = GateType{NAME}

    @eval begin

        $NAME() = gate($GT)

        function $NAME(addr::Int)
            (gate($GT), addr)
        end

        function $NAME(r::UnitRange)
            (gate($GT), r)
        end

        function $NAME(num_qubit::Int, addr::Int)
            kron(num_qubit, (1, gate($GT)))
        end

        function $NAME(num_qubit::Int, r)
            kron(num_qubit, (i, gate($GT)) for i in r)
        end

    end

end


import Base: start, next, done, length, eltype

struct CircuitPlan{B, T}
    reg::Register{B, T}
    seq::Sequence
end

start(itr::CircuitPlan) = 1, Dict()
done(itr::CircuitPlan, state) = state[1] > length(itr.seq.list)
length(itr::CircuitPlan) = length(itr.seq.list)
eltype(itr::CircuitPlan) = eltype(itr.seq.list)

function next(itr::CircuitPlan, state)
    i, info = state
    block = itr.seq.list[i]
    info["iblock"] = i
    info["current"] = block
    if i < length(itr.seq.list)
        info["next"] = itr.seq.list[i+1]
    end

    apply!(itr.reg, block)
    return info, (i+1, info)
end

import Base: >>
export >>

function >>(reg::Register, block::Sequence)
    CircuitPlan(reg, block)
end

function >>(reg::Register, block::AbstractBlock)
    CircuitPlan(reg, sequence(block))
end

function >>(plan::CircuitPlan, block::AbstractBlock)
    push!(plan.seq, block)
    plan
end

function show(io::IO, plan::CircuitPlan)
    println(io, "Circuit Excution Plan:")

    println(io, plan.reg)
    println(io, "----")
    for (i, each) in enumerate(plan.seq.list)
        print(io, "    ", each)

        if i != length(plan.seq.list)
            print(io, "\n")
            println(io, "----")
        end
    end
end
