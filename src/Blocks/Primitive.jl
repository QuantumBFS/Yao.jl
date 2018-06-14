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

function dispatch!(f::Function, x::PrimitiveBlock, params...)
    dispatch!(x, (parameters(x) .+ params)...)
    x
end

cache_key(x::PrimitiveBlock) = parameters(x)
parameter_type(x::PrimitiveBlock) = eltype(parameters(x))

include("ConstGate.jl")
include("PhaseGate.jl")
include("ShiftGate.jl")
include("RotationGate.jl")
include("SwapGate.jl")
