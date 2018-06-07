# for BLOCK in [
#     # primitive
#     # ConstGate,
#     PhaseGate,
#     RotationGate,
#     # composite blocks
#     ChainBlock,
#     KronBlock,
#     ControlBlock,
#     Roller,
#     # others
#     Concentrator,
#     # Sequence,
#     Measure,
#     CachedBlock,
# ]
#     @eval begin
#         # 1. when input is register, call apply!
#         (x::$BLOCK)(reg::AbstractRegister, params...) = apply!(reg, x, params...)
#         # 2. when input is a block, compose as function call
#         (x::$BLOCK)(b::AbstractBlock) = reg->apply!(apply!(reg, b), x)
#         # 3. when input is a signal, compose as function call
#         (x::$BLOCK)(s::Signal) = reg->apply!(reg, x, s)
#     end
# end
