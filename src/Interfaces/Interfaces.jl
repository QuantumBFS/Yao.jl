module Interfaces

using Reexport
using ..Registers
using ..Blocks
using ..Blocks: _blockpromote
using CacheServers
using ..Intrinsics
using MacroTools: @forward

# import package configs
import ..Yao: DefaultType
import ..Blocks: expect, blockfilter, gradient, backward!
import ..Intrinsics: isunitary, ishermitian, iscommute, isreflexive

@reexport using ..Registers

# Macros
export @const_gate

# Block APIs
export mat, apply!, parameters, nparameters, dispatch!, datatype, adjoint, subblocks
export expect, blockfilter, gradient, backward!

# Intrinsic APIs
export isunitary, ishermitian, iscommute, isreflexive

# Candies
export ⊗

include("Signal.jl")
include("Primitive.jl")
include("Composite.jl")
include("Measure.jl")
include("Function.jl")
include("Sequential.jl")
include("TagBlock.jl")
include("Candies.jl")

end
