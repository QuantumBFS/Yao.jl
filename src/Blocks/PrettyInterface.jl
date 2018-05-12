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

    function $NAME(num_qubit::Int, addr::Int)
        kron(num_qubit, (1, gate(X)))
    end

    function $NAME(num_qubit::Int, r)
        kron(num_qubit, (i, gate($GTYPE)) for i in r)
    end

end

end

# 2. control block
export C

function C(total, controls::Int...)
    block_and_addr->ControlBlock(total, [controls...], block_and_addr...)
end

# export CNOT

# function CNOT(a, b)
#     control(a, gate(X), b)
# end

# function CNOT(n, a, b)
#     ca = a - min(a, b) + 1
#     cb = b - min(a, b) + 1
#     kron(n, (min(a, b), control(ca, gate(X), cb)))
# end