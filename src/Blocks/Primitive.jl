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

function print_block(io::IO, x::PrimitiveBlock)

    @static if VERSION < v"0.7-"
        print(io, summary(x))
    else
        summary(io, x)
    end

end


include("ConstGate.jl")
include("PhaseGate.jl")
include("ShiftGate.jl")
include("RotationGate.jl")
include("SwapGate.jl")
