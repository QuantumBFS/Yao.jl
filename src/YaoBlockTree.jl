module YaoBlockTree

include("utils.jl")
# include("traits.jl")

include("abstract_block.jl")
include("block_map.jl")

# concrete blocks
include("routines.jl")
include("primitive/primitive.jl")
include("composite/composite.jl")

include("algebra.jl")
include("blocktools.jl")
include("layout.jl")

include("deprecations.jl")

end # YaoBlockTree
