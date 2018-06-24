module Zoo

using ..Yao
using ..Blocks
using ..Registers
using ..LuxurySparse
import ..Blocks: mat, dispatch!, nparameters, parameters, cache_key, print_block, _make_rot_mat
import Base: ==, copy, hash


# Block APIs
export QFT
export diff_circuit, num_gradient, rotter, cnot_entangler, opgrad, collect_rotblocks

include("QFT.jl")
include("Differential.jl")
include("RotBasis.jl")

end
