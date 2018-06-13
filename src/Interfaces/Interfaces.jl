module Interfaces

using Reexport
using ..Registers
using ..Blocks
using ..Blocks: _blockpromote
using ..CacheServers

# import package configs
import ..Yao: DefaultType

@reexport using ..Registers

# Macros
export @const_gate

# Block APIs
export mat, apply!

include("Signal.jl")
include("Primitive.jl")
include("Composite.jl")
include("Measure.jl")
include("Cache.jl")

export on, on!

function apply_on!(r::AbstractRegister, block::AbstractBlock, params...; kwargs...)
    apply!(r, block, params...; kwargs...)
end

function apply_on!(r::AbstractRegister, lf::Function, params...; kwargs...)
    apply!(r, lf(nactive(r)), params...; kwargs...)
end

"""
    on(register, [params...]) -> f(block)

Returns a lambda function that takes a block as its argument with
configurations on a copy of this `register`.
"""
function on(r::AbstractRegister, params...; kwargs...)
    x->apply_on!(copy(r), x, params...; kwargs...)
end

"""
    on!(register, [params...]) -> f(block)

Returns a lambda function that takes a block as its argument with
configurations on this `register` in place.
"""
function on!(r::AbstractRegister, params...; kwargs...)
    x->apply_on!(r, x, params...; kwargs...)
end

end
