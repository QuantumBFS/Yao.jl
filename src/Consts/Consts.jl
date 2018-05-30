export Const

# TODO: merge Dense constant generator and Sparse constant generator together.

module Const

import ..LuxurySparse: PermMatrix, Identity
import ..Yao
using Compat

const SYM_LIST = [
    (:P0, sparse(Yao.DefaultType[1 0;0 0])),
    (:P1, sparse(Yao.DefaultType[0 0;0 1])),
    (:X, PermMatrix([2,1], Yao.DefaultType[1+0im, 1])),
    (:Y, PermMatrix([2,1], Yao.DefaultType[-im, im])),
    (:Z, Diagonal(Yao.DefaultType[1+0im, -1])),
    (:I2, Identity{2, Complex128}()),
    (:H, (elem = 1 / sqrt(2); Yao.DefaultType[elem elem; elem -elem])),
    (:CNOT, PermMatrix([1, 2, 4, 3], ones(Yao.DefaultType, 4))),
    (:Toffoli, PermMatrix([1, 2, 3, 4, 5, 6, 8, 7], ones(Yao.DefaultType, 8))),
    (:Pu, sparse([1], [2], [1+0im], 2, 2)),
    (:Pd, sparse([2], [1], [1+0im], 2, 2)),
]

const TYPE_LIST = [
    (:CF16, ComplexF16),
    (:CF32, ComplexF32),
    (:CF64, ComplexF64),
]

include("Default.jl")
include("Dense.jl")
include("Sparse.jl")

end