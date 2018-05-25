module QuCircuit

using Compat

include("Consts/Consts.jl")
include("MathUtils.jl")

# include("Register.jl")
include("Register/Register.jl")
include("Blocks/Blocks.jl")

include("Cache/Cache.jl")

include("PrettyInterface.jl")

include("Composer.jl")

end # module
