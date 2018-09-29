module QuAlgorithmZoo

using LuxurySparse, LinearAlgebra
using Yao
using Yao.Intrinsics
using Yao.Registers
using Yao.Blocks
import Yao.Blocks: mat, dispatch!, nparameters, parameters, cache_key, print_block, _make_rot_mat, apply!, PrimitiveBlock
import Base: ==, copy, hash
import Yao.Intrinsics: ishermitian, isreflexive, isunitary

export openbox

"""
For a black box, like QFTBlock, you can get its white box (loyal simulation) using this function.
"""
function openbox end

include("Miscellaneous.jl")
include("QFT.jl")
include("Differential.jl")
include("RotBasis.jl")
include("Grover.jl")
include("PhaseEstimation.jl")
include("HHL.jl")


end # module
