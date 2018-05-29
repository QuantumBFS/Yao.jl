# include("Macros.jl")


# blocks can only be constructed through factory methods

# 1. primitive blocks

# 1.2 phase gate
# 1.2.1 global phase
export phase
phase(::Type{T}, theta) where {T <: Complex} = PhaseGate{:global, real(T)}(theta)
phase(theta=0.0) = phase(CircuitDefaultType, theta)

# 1.2.2 phase shift
export shift
shift(::Type{T}, theta) where {T <: Complex} = PhaseGate{:shift, real(T)}(theta)
shift(theta=0.0) = shift(CircuitDefaultType, theta)

# 1.3 rotation gate
export Rx, Ry, Rz, rot

for (FNAME, NAME) in [
    (:Rx, :X),
    (:Ry, :Y),
    (:Rz, :Z),
]

    GT = Symbol(join([NAME, "Gate"]))
    @eval begin
        $FNAME(::Type{T}, theta=0.0) where {T <: Complex} = RotationGate{real(T), $GT{T}}($NAME(T), theta)
        $FNAME(theta=0.0) = $FNAME(CircuitDefaultType, theta)
    end

end

rot(::Type{T}, U::GT, theta=0.0) where {T, GT} = RotationGate{real(T), GT}(U, theta)
rot(U::MatrixBlock, theta=0.0) = rot(CircuitDefaultType, U, theta)


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

function control(total::Int, controls)
    block_and_addr->ControlBlock{total}([controls...], block_and_addr...)
end

function control(controls)
    block_and_addr->ControlBlock([controls...], block_and_addr...)
end

function C(controls::Int...)
    function _C(block_and_addr)
        total->ControlBlock{total}([controls...], block_and_addr...)
    end
end

# 2.4 roller

export roll

roll(n::Int, block::MatrixBlock) = Roller{n}(block)

function roll(blocks::MatrixBlock...)
    T = promote_type(datatype(each) for each in blocks)
    N = sum(x->nqubits(x), blocks)
    Roller{N, T}(blocks)
end

roll(block::MatrixBlock) = n->roll(n, block)

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

struct Signal
    sig::UInt
end

export signal
signal(x::Int) = Signal(UInt(x))

for BLOCK in [
    # primitive
    # ConstGate,
    PhaseGate,
    RotationGate,
    # composite blocks
    ChainBlock,
    KronBlock,
    ControlBlock,
    Roller,
    # others
    Concentrator,
    Sequence,
    Measure,
    Cached,
]
    @eval begin
        # 1. when input is register, call apply!
        (x::$BLOCK)(reg::Register) = apply!(reg, x)
        # 2. when input is a block, compose as function call
        (x::$BLOCK)(b::AbstractBlock) = reg->apply!(apply!(reg, b), x)
        # 3. when input is a signal, compose as function call
        (x::$BLOCK)(s::Signal) = reg->apply!(reg, x, s)
    end
end

# Abbreviations

# # 1.Pauli Gates & Hadmard
# export X, Y, Z, H

# for NAME in [:X, :Y, :Z, :H]

#     GT = Val{NAME}
#     @eval begin

#         $NAME() = gate($GT)

#         function $NAME(addr::Int)
#             (gate($GT), addr)
#         end

#         function $NAME(r::UnitRange)
#             (gate($GT), r)
#         end

#         function $NAME(num_qubit::Int, addr::Int)
#             KronBlock{num_qubit}(1=>gate($GT))
#         end

#         function $NAME(num_qubit::Int, r)
#             KronBlock{num_qubit}(collect(r), collect(gate($GT) for i in r))
#         end

#     end

# end


# import Base: start, next, done, length, eltype

# struct CircuitPlan{B, T}
#     reg::Register{B, T}
#     seq::Sequence
# end

# start(itr::CircuitPlan) = 1, Dict()
# done(itr::CircuitPlan, state) = state[1] > length(itr.seq.list)
# length(itr::CircuitPlan) = length(itr.seq.list)
# eltype(itr::CircuitPlan) = eltype(itr.seq.list)

# function next(itr::CircuitPlan, state)
#     i, info = state
#     block = itr.seq.list[i]
#     info["iblock"] = i
#     info["current"] = block
#     if i < length(itr.seq.list)
#         info["next"] = itr.seq.list[i+1]
#     end

#     apply!(itr.reg, block)
#     return info, (i+1, info)
# end

# import Base: >>
# export >>

# function >>(reg::Register, block::Sequence)
#     CircuitPlan(reg, block)
# end

# function >>(reg::Register, block::AbstractBlock)
#     CircuitPlan(reg, Sequence(block))
# end

# function >>(plan::CircuitPlan, block::AbstractBlock)
#     push!(plan.seq, block)
#     plan
# end

# function show(io::IO, plan::CircuitPlan)
#     println(io, "Circuit Excution Plan:")

#     println(io, plan.reg)
#     println(io, "----")
#     for (i, each) in enumerate(plan.seq.list)
#         print(io, "    ", each)

#         if i != length(plan.seq.list)
#             print(io, "\n")
#             println(io, "----")
#         end
#     end
# end

