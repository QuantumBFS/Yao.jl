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
include("layout.jl")
include("treeutils/treeutils.jl")

include("autodiff/autodiff.jl")
export AD

include("deprecations.jl")

end # YaoBlocks
