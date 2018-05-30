import Block: XGate, YGate, ZGate

GATES = [:X, :Y, :Z]
for G in GATES
    GATE = Symbol(G, :Gate)
    @eval mat(g::$GATE{MT}) where MT = $(Symbol(:PAULI_,G))
end

#################### Single Control Block ######################
struct SingleControlBlock{GT<:MatrixBlock, N, MT} <: CompositeBlock{N, MT}
    target::GT
    cbit::Int
    ibit::Int
end

blocks(cb::SingleControlBlock) = [rb.target]

for (G, MATFUNC) in zip(GATES, [:cxgate, :cygate, :czgate])
    GATE = Symbol(G, :Gate)
    @eval function mat(cb::SingleControlBlock{$GATE, N, MT}) where {N, MT}
        $MATFUNC(MT, N, cb.cbit, cb.ibit)
    end
end

#################### Repeated Block ######################
mutable struct RepeatedBlock{GT<:MatrixBlock, N, MT} <: CompositeBlock{N, MT}
    block::GT
    bits::Vector{Int}
end

for (G, MATFUNC) in zip(GATES, [:xgate, :ygate, :zgate])
    GGate = Symbol(G, :Gate)
    @eval function mat(cb::RepeatedBlock{$GGate, N, MT}) where {N, MT}
        $MATFUNC(MT, N, cb.bits)
    end
end

blocks(rb::RepeatedBlock) = [rb.block]
