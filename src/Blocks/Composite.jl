"""
    CompositeBlock{N, T} <: MatrixBlock{N, T}

abstract supertype which composite blocks will inherit from.
"""
abstract type CompositeBlock{N, T} <: MatrixBlock{N, T} end

# composite blocks are iterables
import Base: start, next, done, eltype, length

# iterate_blocks

# composite blocks are indexable
import Base: getindex, setindex!, map!, eachindex

function map!(f::Function, dst::CompositeBlock, src::CompositeBlock)
    @assert length(dst) == length(src) "composite block should have the same size"

    for (di, si) in zip(eachindex(dst), eachindex(src))
        dst[di] = f(src[si])
    end
    dst
end

function dispatch!(c::CompositeBlock, params::Vector)
    for each in blocks(c)
        dispatch!(each, params)
    end
    c
end

# TODO: optimize for blocks full of parameters
function dispatch!(f::Function, c::CompositeBlock, params::Vector)
    for each in blocks(c)
        dispatch!(f, each, params)
    end
    c
end


include("ChainBlock.jl")
include("KronBlock.jl")
include("Control.jl")
include("Roller.jl")
