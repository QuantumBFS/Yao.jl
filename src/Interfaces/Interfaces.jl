module Interfaces

using ..Registers
using ..Blocks
using ..CacheServers

import ..Blocks: measure

# import package configs
import ..Yao: DefaultType

# Macros
export @const_gate

export cache, update_cache, pull, iscached, iscacheable

include("Signal.jl")
include("Primitive.jl")
include("Composite.jl")
include("Measure.jl")
include("Cache.jl")
include("Callables.jl")

export focus

"""
    focus(orders...) -> Concentrator

focus serveral lines.
"""
focus(orders...) = Concentrator(orders...)

end