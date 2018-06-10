# composite blocks are iterables
import Base: start, next, done, eltype, length

# composite blocks are indexable
import Base: getindex, setindex!, map!, eachindex

# Additional APIs
export blocks, CompositeBlock


"""
    CompositeBlock{N, T} <: MatrixBlock{N, T}

abstract supertype which composite blocks will inherit from.

# extended APIs

`blocks`: get an iteratable of all blocks contained by this `CompositeBlock`

"""
abstract type CompositeBlock{N, T} <: MatrixBlock{N, T} end

"""
    blocks(composite_block)

get an iterator that iterate through all sub-blocks.
"""
function blocks end

function map!(f::Function, dst::CompositeBlock, itr)
    @assert length(dst) >= length(itr) "composite block should have the same size"

    for (di, each) in zip(eachindex(dst), itr)
        dst[di] = f(each)
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

# TODO: make this a lazy list
function parameters(c::CompositeBlock)
    params = []
    for each in blocks(c)
        append!(params, parameters(each))
    end
    params
end

#################
# Dispatch Rules
#################

# TODO: optimize for blocks full of parameters



"""
    dispatch!(f, c, params) -> c

dispatch parameters and tweak it according to callback function `f(original, parameter)->new`

dispatch a vector of parameters to this composite block according to
each sub-block's number of parameters.
"""
function dispatch!(f::Function, c::CompositeBlock, params::Vector)
    count = 0
    for each in blocks(c)
        # NOTE: small copy is faster (?)
        if nparameters(each) > 0
            if nparameters(each) == 1
                dispatch!(f, each, params[count + 1])
                count += 1
            else
                dispatch!(f, each, params[count + 1 : count + nparameters(each)])
                count += nparameters(each)
            end
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

==(lhs::CompositeBlock, rhs::CompositeBlock) = false

include("ChainBlock.jl")
include("KronBlock.jl")
include("Control.jl")
include("Roller.jl")
include("Repeated.jl")
