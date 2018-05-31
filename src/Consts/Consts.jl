export Const

# TODO: merge Dense constant generator and Sparse constant generator together.

module Const

using Compat
using Compat.LinearAlgebra
using Compat.SparseArrays


const SYM_LIST = [
    (:P0, [1 0;0 0]),
    (:P1, [0 0;0 1]),
    (:X, [0 1;1 0]),
    (:Y, [0 -im; im 0]),
    (:Z, [1 0;0 -1]),
    (:I2, eye(2)),
    (:H, (elem = 1 / sqrt(2); [elem elem; elem -elem])),
]

const TYPE_LIST = [
    (:CF16, ComplexF16),
    (:CF32, ComplexF32),
    (:CF64, ComplexF64),
]

include("Dense.jl")
include("Sparse.jl")

end