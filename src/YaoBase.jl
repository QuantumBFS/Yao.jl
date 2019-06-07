"""
Base module for Yao.
"""
module YaoBase

using LinearAlgebra, LuxurySparse, SparseArrays, Random

include("utils/ast_tools.jl")

include("utils/constants.jl")
include("utils/math.jl")
include("utils/interface.jl")

include("error.jl")
include("abstract_register.jl")
include("adjoint_register.jl")

include("inspect.jl")
include("instruct.jl")

# compat with older version of dependencies
include("compat.jl")

# deprecation warns
include("deprecations.jl")

end # module
