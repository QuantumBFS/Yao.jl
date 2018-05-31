# __precompile__()

"""
Flexible, Extensible Framework for Quantum Algorithm Design.

## Environment Variables

`YaoDefaultType`: set default type used in simulation.

"""
module Yao

using Compat, MacroTools
using Compat.Random
using Compat.LinearAlgebra
using Compat.SparseArrays

PKGNAME = "Yao"
ENVNAME = join([PKGNAME, "DefaultType"])

@static if haskey(ENV, ENVNAME)
    const CircuitDefaultType = parse(ENV[ENVNAME])
else
    const CircuitDefaultType = ComplexF64
end

include("Consts/Consts.jl")
include("MathUtils.jl")

include("Register/Register.jl")
include("Blocks/Blocks.jl")

include("Cache/Cache.jl")

include("Interfaces/Interfaces.jl")

include("show.jl")
include("docs.jl")

end # module
