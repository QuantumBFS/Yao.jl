# __precompile__()

"""
Flexible, Extensible Framework for Quantum Algorithm Design.

## Environment Variables

`YaoDefaultType`: set default type used in simulation.

"""
module Yao

using Compat, MacroTools, Reexport
using Compat.Random
using Compat.LinearAlgebra
using Compat.SparseArrays

PKGNAME = "Yao"
ENVNAME = join([PKGNAME, "DefaultType"])

@static if haskey(ENV, ENVNAME)
    const DefaultType = parse(ENV[ENVNAME])
else
    const DefaultType = ComplexF64
end

include("APIs.jl")

include("LuxurySparse/LuxurySparse.jl")
include("Intrinsics/Intrinsics.jl")
include("Registers/Registers.jl")
include("Blocks/Blocks.jl")
include("Cache/Cache.jl")

include("Interfaces/Interfaces.jl")

# include("show.jl")
# include("docs.jl")

@reexport using .Interfaces
@reexport using .Registers # TODO: move this to interfaces

end # module
