"""
    CompositeBlock{N, T} <: MatrixBlock{N, T}

abstract supertype which composite blocks will inherit from.

# extended APIs

`blocks`: get an iteratable of all blocks contained by this `CompositeBlock`

"""
abstract type CompositeBlock{N, T} <: MatrixBlock{N, T} end

# composite blocks are iterables
import Base: start, next, done, eltype, length

"""
    blocks(composite_block)

get an iterator that iterate through all sub-blocks.
"""
function blocks end

# composite blocks are indexable
import Base: getindex, setindex!, map!, eachindex

function map!(f::Function, dst::CompositeBlock, src::CompositeBlock)
    @assert length(dst) == length(src) "composite block should have the same size"

    for (di, si) in zip(eachindex(dst), eachindex(src))
        dst[di] = f(src[si])
    end
    dst
end

function nparameters(c::CompositeBlock)
    count = 0
    for each in blocks(c)
        count += nparameters(each)
    end
    count
end

#################
# Dispatch Rules
#################

# TODO: optimize for blocks full of parameters


"""
    dispatch!(block, vector)

dispatch a vector of parameters to this composite block according to
each sub-block's number of parameters.

to update parameters with certain rules, see `dispatch!(f, block, params)`
"""
dispatch!(c::CompositeBlock, params::Vector) = dispatch!((o, n)->n, c, params...)

"""
    dispatch!(block, params...)

dispatch parameters according to parameterized blocks' order.
"""
dispatch!(c::CompositeBlock, params...) = dispatch!((o, n)->n, c, params...)

"""
    dispatch!(f, c, params) -> c

dispatch parameters and tweak it according to callback function `f(original, parameter)->new`
"""
function dispatch!(f::Function, c::CompositeBlock, params::Vector)
    count = 0
    for each in blocks(c)
        # NOTE: small copy is faster (?)
        if nparameters(each) == 1
            dispatch!(f, each, params[count + 1])
            count += 1
        else
            dispatch!(f, each, params[count + 1 : count + nparameters(each)])
            count += nparameters(each)
        end
    end
    c
end

function dispatch!(f::Function, c::CompositeBlock, params...)
    idx = 1
    for each in blocks(c)
        if nparameters(each) > 0
            dispatch!(f, each, params[idx])
            idx += 1
        end
    end
    c
end

include("ChainBlock.jl")
include("KronBlock.jl")
include("Control.jl")
include("Roller.jl")
