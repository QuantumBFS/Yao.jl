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

export on, on!, with, with!

function with(f::Function, r::AbstractRegister)
    f(copy(r))
end

function with!(f::Function, r::AbstractRegister)
    f(r)
end

function on(r::AbstractRegister, params...)
    block->apply!(copy(r), block, params...)
end

function on!(r::AbstractRegister, params...)
    block->apply!(r, block, params...)
end

export focus

"""
    focus(orders...) -> Concentrator

focus serveral lines.
"""
focus(orders...) = Concentrator(orders...)

end