"""
Base module for Yao.
"""
module YaoBase

using LinearAlgebra, LuxurySparse, SparseArrays

# TODO: polish this
include("basis.jl")
# TODO: polish this
include("utils/math.jl")
# TODO: polish this
include("macrotools.jl")


include("exceptions.jl")
include("inspect.jl")
include("instruct.jl")

include("utils/interface.jl")
include("abstract_register.jl")
include("adjoint_register.jl")

# TestTools
include("utils/test_utils.jl")

end # module
