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

export with, with!

struct Context{R <: AbstractRegister}
    r::R
end

import Base: |>

function |>(r::AbstractRegister, block::AbstractBlock)
    apply!(r, block)
end

function |>(io::Context, block::AbstractBlock)
    apply!(io.r, block)
end

"""
    with!(f, register)

Provide a writable context for blocks operating this register.
"""
function with!(f::Function, r::AbstractRegister)
    f(Context(r))
    r
end

"""
    with(f, register)

Provide a copy context for blocks operating this register.
"""
function with(f::Function, r::AbstractRegister)
    cr = copy(r)
    f(Context(cr))
    cr
end

end
