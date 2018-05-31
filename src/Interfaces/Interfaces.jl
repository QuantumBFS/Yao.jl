module Interfaces

using ..Registers
using ..Blocks
using ..CacheServers

# import package configs
import ..Yao: DefaultType

# Macros
export @const_gate

include("Signal.jl")
include("Primitive.jl")
include("Composite.jl")
include("Measure.jl")
include("Callables.jl")
include("Compose.jl")

export focus

"""
    focus(orders...) -> Concentrator

focus serveral lines.
"""
focus(orders...) = Concentrator(orders...)

end