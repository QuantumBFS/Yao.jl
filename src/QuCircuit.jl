"""
Flexible, Extensible Framework for Quantum Algorithm Design.

## Environment Variables

`QuCircuitDefaultType`: set default type used in simulation.

"""
module QuCircuit

using Compat, MacroTools

PKGNAME = "QuCircuit"
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

include("docs.jl")

end # module
