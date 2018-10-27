"""
Extensible Framework for Quantum Algorithm Design for Humans.

简单易用可扩展的量子算法设计框架。
"""
module Yao

export 幺

"""
Extensible Framework for Quantum Algorithm Design for Humans.

简单易用可扩展的量子算法设计框架。

幺 means unitary in Chinese.
"""
const 幺 = Yao

using MacroTools, Reexport, LuxurySparse
using Random, LinearAlgebra, SparseArrays

PKGNAME = "Yao"
ENVNAME = join([PKGNAME, "DefaultType"])

@static if haskey(ENV, ENVNAME)
    const DefaultType = parse(ENV[ENVNAME])
else
    const DefaultType = ComplexF64
end

include("APIs.jl")

include("Intrinsics/Intrinsics.jl")
include("Registers/Registers.jl")
include("Blocks/Blocks.jl")
include("Boost/Boost.jl")
include("Interfaces/Interfaces.jl")

include("QASM/QASM.jl")

@reexport using .Interfaces

end # module
