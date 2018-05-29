# include("Macros.jl")
# include("PositionBlock.jl")

include("Primitives.jl")
include("Composite.jl")
include("Measure.jl")

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
        (x::$BLOCK)(reg::Register, params...) = apply!(reg, x, params...)
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

