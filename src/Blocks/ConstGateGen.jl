using .ConstGateTools

# note!!!
# Here, we don't need gates like swap^α and √X.
# swap^α = rot(SWAP, -α*π)
# √X = rot(X, -α*π)
# since both of them are reflexive.

const SYM_LIST = [
    (:P0, sparse(DefaultType[1 0;0 0])),
    (:P1, sparse(DefaultType[0 0;0 1])),
    (:X, PermMatrix([2,1], DefaultType[1+0im, 1])),
    (:Y, PermMatrix([2,1], DefaultType[-im, im])),
    (:Z, Diagonal(DefaultType[1+0im, -1])),
    (:S, Diagonal(DefaultType[1, im])),
    (:Sdag, Diagonal(DefaultType[1, -im])),
    (:T, Diagonal(DefaultType[1, exp(π*im/4)])),
    (:Tdag, Diagonal(DefaultType[1, exp(-π*im/4)])),
    (:I2, IMatrix{2, DefaultType}()),
    (:H, (elem = 1 / sqrt(2); DefaultType[elem elem; elem -elem])),
    (:CNOT, PermMatrix([1, 4, 3, 2], ones(DefaultType, 4))),
    (:SWAP, PermMatrix([1, 3, 2, 4], ones(DefaultType, 4))),
    (:Toffoli, PermMatrix([1, 2, 3, 8, 5, 6, 7, 4], ones(DefaultType, 8))),
    (:Pu, sparse([1], [2], DefaultType[1+0im], 2, 2)),
    (:Pd, sparse([2], [1], DefaultType[1+0im], 2, 2)),
]

for (NAME, MAT) in SYM_LIST
    GT = Symbol(NAME, "Gate")
    @eval begin
        export $NAME, $GT
        @const_gate $NAME = $MAT
    end
end

adjoint(::PuGate) = Pd
adjoint(::PdGate) = Pu
adjoint(::SGate) = Sdag
adjoint(::SdagGate) = S
adjoint(::TGate) = Tdag
adjoint(::TdagGate) = T
