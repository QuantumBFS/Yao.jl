export PrimitiveBlock

"""
    PrimitiveBlock{N, T} <: MatrixBlock{N, T}

abstract type that all primitive block will subtype from. A primitive block
is a concrete block who can not be decomposed into other blocks. All composite
block can be decomposed into several primitive blocks.

NOTE: subtype for primitive block with parameter should implement `hash` and `==`
method to enable key value cache.
"""
abstract type PrimitiveBlock{N, T} <: MatrixBlock{N, T} end

isprimitive(blk::PrimitiveBlock) = true

function dispatch!(x::PrimitiveBlock, params...)
    dispatch!(x, params)
end

dispatch!(f::Function, x::PrimitiveBlock, params...) = dispatch!(f, x, params)

function dispatch!(f::Function, x::PrimitiveBlock, itr)
    dispatch!(x, map(f, parameters(x), itr))
    x
end

cache_key(x::PrimitiveBlock) = parameters(x)
parameter_type(x::PrimitiveBlock) = eltype(parameters(x))
nparameters(x::PrimitiveBlock) = length(parameters(x))

include("ConstGate.jl")
include("PhaseGate.jl")
include("ShiftGate.jl")
include("RotationGate.jl")
include("TimeEvolution.jl")
include("SwapGate.jl")
include("ReflectBlock.jl")
include("GeneralMatrixGate.jl")
include("MathBlock.jl")
