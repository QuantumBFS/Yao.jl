"""
Standard basic quantum circuit simulator building blocks.

This is a component package for [Yao.jl](https://github.com/QuantumBFS/Yao.jl). It contains the abstract definitions and basic implementation of Yao's circuit building blocks.
"""
module YaoBlocks

using LinearAlgebra

include("utils.jl")
# include("traits.jl")

include("abstract_block.jl")

# concrete blocks
include("routines.jl")
include("primitive/primitive.jl")
include("composite/composite.jl")

include("algebra.jl")
include("blocktools.jl")
include("measure_ops.jl")
include("layout.jl")
include("treeutils/treeutils.jl")

include("autodiff/autodiff.jl")
export AD, Optimise

include("deprecations.jl")

end # YaoBlocks
