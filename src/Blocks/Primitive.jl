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

cache_key(x::PrimitiveBlock) = iparameters(x)

include("ConstGate.jl")
include("PhaseGate.jl")
include("ShiftGate.jl")
include("RotationGate.jl")
include("TimeEvolution.jl")
include("SwapGate.jl")
include("ReflectBlock.jl")
include("GeneralMatrixGate.jl")
include("MathBlock.jl")
