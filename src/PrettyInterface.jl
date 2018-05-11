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

for (NAME, TYPE) in [
    (:X, X),
    (:Y, Y),
    (:Z, Z),
    (:H, Hadmard)
]

@eval begin

    function $NAME(addr::Int)
        (gate($TYPE), addr)
    end

    function $NAME(num_qubit::Int, addr::Int)
        BlockWithAddr(
            kron(gate($TYPE) for i in 1:num_qubit),
            addr,
        )
    end

    function $NAME(num_qubit::Int, r)
        kron(num_qubit, (i, gate($TYPE)) for i in r)
    end

end

end

# 2. control block
export control

function control(x::Tuple{<:AbstractBlock, <:Integer}, cbit)
    control(cbit, x[1], x[2])
end

function control(x::ControlBlock, cbit)
    control(cbit, x, max(x.control, x.pos))
end

control(cbit) = x->control(x, cbit)
