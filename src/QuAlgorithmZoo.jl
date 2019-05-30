module QuAlgorithmZoo

using LuxurySparse, LinearAlgebra
using MacroTools: @forward
using Yao, YaoBlocks.ConstGate, BitBasis
using YaoArrayRegister: u1rows!
import Yao: mat, dispatch!, niparams, getiparams, setiparams!, cache_key, print_block, apply!, PrimitiveBlock, ishermitian, isunitary, isreflexive
import YaoBlocks: render_params
import Base: ==, copy, hash

export openbox

"""
    openbox(block::AbstractBlock) -> AbstractBlock

For a black box, like QFTBlock, you can get its white box (loyal simulation) using this function.
"""
function openbox end

include("Miscellaneous.jl")
include("sequence.jl")
include("Diff.jl")
include("Adam.jl")
include("QFT.jl")
include("CircuitBuild.jl")
include("QCOptProblem.jl")
include("RotBasis.jl")
include("Grover.jl")
include("PhaseEstimation.jl")
include("HHL.jl")
include("hamiltonian_solvers.jl")
include("HadamardTest.jl")
include("lin_diffEq_HHL.jl")
include("QSVD.jl")


end # module
