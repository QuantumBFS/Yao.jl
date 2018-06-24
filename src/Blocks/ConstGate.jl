export ConstantGate

"""
    ConstantGate{N, T} <: PrimitiveBlock{N, T}

Abstract type for constant gates.
"""
abstract type ConstantGate{N, T} <: PrimitiveBlock{N, T} end

@static if VERSION < v"0.7-"
    include("ConstGateTools.jl")
else
    include("ConstGateTools2.jl")
end

cache_key(x::ConstantGate) = 0x1

include("ConstGateGen.jl")
