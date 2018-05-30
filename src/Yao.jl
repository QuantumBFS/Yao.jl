# __precompile__()

"""
Flexible, Extensible Framework for Quantum Algorithm Design.

## Environment Variables

`YaoDefaultType`: set default type used in simulation.

"""
module Yao

using Compat, Reexport

PKGNAME = "Yao"
ENVNAME = join([PKGNAME, "DefaultType"])

@static if haskey(ENV, ENVNAME)
    const DefaultType = parse(ENV[ENVNAME])
else
    const DefaultType = ComplexF64
end

include("docs.jl")
include("LuxurySparse/LuxurySparse.jl")
include("Basis.jl")
include("MathUtils.jl")

include("Consts/Consts.jl")
include("Intrinsics/Intrinsics.jl")

include("Register/Register.jl")
include("Blocks/Blocks.jl")

include("Cache/Cache.jl")

include("Interfaces/Interfaces.jl")
include("APIs.jl")

end # module
