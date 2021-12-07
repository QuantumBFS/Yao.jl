export AD

"""
    AD

This module provides the basic routines and syntax for automatic differentiation (AD).
However, one need to port this to AD frameworks like [Zygote](https://github.com/FluxML/Zygote.jl),
[Tracker](https://github.com/FluxML/Tracker.jl) or [Yota](https://github.com/dfdx/Yota.jl) to make
it composable with a general Julia program. You can also check the work-in-progress package
[YaoAD](https://github.com/QuantumBFS/YaoAD.jl) that provides this functionality.
"""
module AD

using BitBasis, YaoArrayRegister, YaoBase
using ..YaoBlocks

using SparseArrays, LuxurySparse, LinearAlgebra

include("patches.jl")
include("NoParams.jl")
include("outerproduct_and_projection.jl")
include("adjroutines.jl")
include("mat_back.jl")
include("apply_back.jl")
include("specializes.jl")
include("gradcheck.jl")
include("chainrules_patch.jl")

end
