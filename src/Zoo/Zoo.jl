module Zoo
using Compat

using ..Yao
using ..LuxurySparse
using ..Intrinsics
using ..Registers
using ..Blocks
import ..Blocks: mat, dispatch!, nparameters, parameters, cache_key, print_block, _make_rot_mat, apply!
import Base: ==, copy, hash
import ..Intrinsics: ishermitian, isreflexive, isunitary

export openbox

"""
For a black box, like QFTBlock, you can get its white box (loyal simulation) using this function.
"""
function openbox end

include("QFT.jl")
include("Differential.jl")
include("RotBasis.jl")
include("Grover.jl")

end
