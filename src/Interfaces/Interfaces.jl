module Interfaces

using Reexport
using ..Registers
using ..Blocks
using ..Blocks: _blockpromote
using CacheServers
using ..Intrinsics

# import package configs
import ..Yao: DefaultType
import ..Blocks: expect, blockfilter, gradient, scale, backward

@reexport using ..Registers

# Macros
export @const_gate

# Block APIs
export mat, apply!, parameters, nparameters, dispatch!, datatype, adjoint, subblocks
export expect, blockfilter, gradient, scale, backward

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
