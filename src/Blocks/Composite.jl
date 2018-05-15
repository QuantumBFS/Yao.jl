"""
    CompositeBlock{N, T} <: MatrixBlock{N, T}

abstract supertype which composite blocks will inherit from.
"""
abstract type CompositeBlock{N, T} <: MatrixBlock{N, T} end

# composite blocks are iterables
import Base: start, next, done, eltype, length

# composite blocks are indexable
import Base: getindex, setindex!, map!

function dispatch!(c::CompositeBlock, params::Vector)
    reverse!(params)
    for each in c
        dispatch!(each, params)
    end
    c
end

include("ChainBlock.jl")
include("KronBlock.jl")
include("Control.jl")
