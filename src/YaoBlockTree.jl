module YaoBlockTree

include("utils.jl")

include("abstract_block.jl")
# concrete blocks
include("matrix/matrix.jl")
# include("symbolic/symbolic.jl")

# include("measure.jl")
# include("sequencial.jl")
# include("function.jl")

include("parse_block.jl")

# printings and tools to manipulate
# the tree.
include("layout.jl")
include("blocktree.jl")

include("deprecations.jl")

end # YaoBlockTree
