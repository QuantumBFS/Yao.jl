using SparseArrays, LinearAlgebra, LuxurySparse

# TODO: add documents
# 1. generate a table from SYM_LIST
# 2. auto attach docs to each gate instance and type

# note!!!
# Here, we don't need gates like swap^α and √X.
# swap^α = rot(SWAP, -α*π)
# √X = rot(X, -α*π)
# since both of them are reflexive.
const ConstGateDefaultType = ComplexF64
const SYM_LIST = [
    (:P0, sparse(ConstGateDefaultType[1 0;0 0])),
    (:P1, sparse(ConstGateDefaultType[0 0;0 1])),
    (:X, PermMatrix([2,1], ConstGateDefaultType[1+0im, 1])),
    (:Y, PermMatrix([2,1], ConstGateDefaultType[-im, im])),
    (:Z, Diagonal(ConstGateDefaultType[1+0im, -1])),
    (:S, Diagonal(ConstGateDefaultType[1, im])),
    (:Sdag, Diagonal(ConstGateDefaultType[1, -im])),
    (:T, Diagonal(ConstGateDefaultType[1, exp(π*im/4)])),
    (:Tdag, Diagonal(ConstGateDefaultType[1, exp(-π*im/4)])),
    (:I2, IMatrix{2, ConstGateDefaultType}()),
    (:H, (elem = 1 / sqrt(2); ConstGateDefaultType[elem elem; elem -elem])),
    (:CNOT, PermMatrix([1, 4, 3, 2], ones(ConstGateDefaultType, 4))),
    (:SWAP, PermMatrix([1, 3, 2, 4], ones(ConstGateDefaultType, 4))),
    (:Toffoli, PermMatrix([1, 2, 3, 8, 5, 6, 7, 4], ones(ConstGateDefaultType, 8))),
    (:Pu, sparse([1], [2], ConstGateDefaultType[1+0im], 2, 2)),
    (:Pd, sparse([2], [1], ConstGateDefaultType[1+0im], 2, 2)),
]

for (NAME, MAT) in SYM_LIST
    GT = Symbol(NAME, "Gate")
    @eval begin
        @const_gate $NAME = $MAT
    end
end

Base.adjoint(::PuGate) = Pd
Base.adjoint(::PdGate) = Pu
Base.adjoint(::SGate) = Sdag
Base.adjoint(::SdagGate) = S
Base.adjoint(::TGate) = Tdag
Base.adjoint(::TdagGate) = T

# Docs
"""
    X
    XGate <: ConstantGate{1}

Pauli X gate. `X` is the instance of `XGate`.
"""
X, XGate

"""
    Y
    YGate  <: ConstantGate{1}

Pauli Y gate. `Y` is the instance of `YGate`.
"""
Y, YGate

"""
    Z
    ZGate  <: ConstantGate{1}

Pauli Z gate. `Z` is the instance of `YGate`.
"""
Z, ZGate
