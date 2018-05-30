module Interfaces

using Compat, Reexport

using ..Registers
using ..Blocks
using ..Cache

@reexport using ..Blocks
@reexport using ..Registers

# include("Macros.jl")
include("PositionBlock.jl")
include("Primitive.jl")
include("Composite.jl")
include("Measure.jl")
include("Compose.jl")

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
    # Sequence,
    Measure,
    Cached,
]
    @eval begin
        # 1. when input is register, call apply!
        (x::$BLOCK)(reg::Register, params...) = apply!(reg, x, params...)
        # 2. when input is a block, compose as function call
        (x::$BLOCK)(b::AbstractBlock) = reg->apply!(apply!(reg, b), x)
        # 3. when input is a signal, compose as function call
        (x::$BLOCK)(s::Signal) = reg->apply!(reg, x, s)
    end
end

end