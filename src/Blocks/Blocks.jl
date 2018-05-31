"""
# APIs

### Traits

`nqubits`
`ninput`
`noutput`
`isunitary`
`ispure`
`isreflexive`
`ishermitian`

### Methods

`apply!`
`copy`
`dispatch!`
"""
module Blocks

using Compat
using Compat.Random
using Compat.LinearAlgebra
using Compat.SparseArrays

using MacroTools
using ..Intrinsics
using ..Registers
using ..LuxurySparse
import ..LuxurySparse: I

# import package APIs
import ..Yao
import ..Yao: DefaultType, nqubits, isunitary, isreflexive, nparameters, mat, datatype, dispatch!
import Compat.LinearAlgebra: ishermitian
import Base: hash, ==, eltype, show

# module APIs
export nqubits, ninput, noutput, isunitary, ispure, isreflexive, nparameters, mat, datatype, ishermitian
export apply!, dispatch!

struct AnySize end
struct GreaterThan{N} end
ismatch(::GreaterThan{N}, n::Int) where N = n > N
ismatch(::AnySize, n::Int) = true

include("Core.jl")
include("MatrixBlock.jl")

# others
include("Concentrator.jl")
# include("Sequence.jl")
include("Measure.jl")
include("IOSyntax.jl")

end
