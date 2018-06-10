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

export concentrate

"""
    concentrate(orders...) -> Concentrator

concentrate on serveral lines.
"""
concentrate(nbit::Int, block::AbstractBlock, orders::Vector{Int}) = Concentrator{nbit}(block, orders)

end
