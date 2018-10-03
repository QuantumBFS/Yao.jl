# composite blocks are iterables
import Base: iterate, eltype, length

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

const GeneralComposite = Union{CompositeBlock, Sequential}

function map!(f::Function, dst::GeneralComposite, itr)
    @assert length(dst) >= length(itr) "composite block should have the same size"

    for (di, each) in zip(eachindex(dst), itr)
        dst[di] = f(each)
    end
    dst
end

function parameter_type(c::GeneralComposite)
    promote_type([parameter_type(each) for each in subblocks(c)]...)
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
function dispatch!(c::CompositeBlock, itr)
    @assert nparameters(c) == length(itr) "number of parameters does not match"

    blkitr = Iterators.filter(x->x isa PrimitiveBlock && hasparameter(x), traverse(c))
    pitr = itr
    for each in blkitr
        dispatch!(each, Iterators.take(pitr, nparameters(each)))
        pitr = Iterators.drop(pitr, nparameters(each))
    end
    c
end

function dispatch!(f::Function, c::CompositeBlock, itr)
    @assert nparameters(c) == length(itr) "number of parameters does not match"

    blkitr = Iterators.filter(x->x isa PrimitiveBlock && hasparameter(x), traverse(c))
    pitr = itr
    for each in blkitr
        dispatch!(f, each, Iterators.take(pitr, nparameters(each)))
        pitr = Iterators.drop(pitr, nparameters(each))
    end
    c
end


==(lhs::CompositeBlock, rhs::CompositeBlock) = false

include("ChainBlock.jl")
include("KronBlock.jl")
include("Roller.jl")
include("PauliString.jl")
