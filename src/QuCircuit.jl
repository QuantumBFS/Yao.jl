module QuCircuit

using Compat, MacroTools

const CircuitDefaultType = ComplexF64

include("Consts/Consts.jl")
include("MathUtils.jl")

# include("Register.jl")
include("Register/Register.jl")
include("Blocks/Blocks.jl")

include("Cache/Cache.jl")

include("Interfaces/Interfaces.jl")

include("Composer.jl")

end # module
