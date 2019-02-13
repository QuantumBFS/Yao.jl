"""
Base module for Yao.
"""
module YaoBase

using LinearAlgebra, LuxurySparse, SparseArrays, BitBasis

# TODO: polish this
include("utils/math.jl")

include("utils/interface.jl")
include("abstract_register.jl")
include("adjoint_register.jl")

include("exceptions.jl")
include("inspect.jl")
include("instruct.jl")

# TODO: polish this
include("macrotools.jl")

# TestTools
include("utils/test_utils.jl")

end # module
