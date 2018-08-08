module Interfaces

using Reexport
using ..Registers
using ..Blocks
using ..Blocks: _blockpromote
using CacheServers
using ..Intrinsics

# import package configs
import ..Yao: DefaultType

@reexport using ..Registers

# Macros
export @const_gate

# Block APIs
export mat, apply!, parameters, nparameters, dispatch!, datatype, blocks, adjoint

include("Signal.jl")
include("Primitive.jl")
include("Composite.jl")
include("Measure.jl")
include("Function.jl")
include("Sequential.jl")
include("Cache.jl")

end
