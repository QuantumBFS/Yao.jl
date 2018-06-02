export ConstantGate
abstract type ConstantGate{N, T} <: PrimitiveBlock{N, T} end

include("ConstGateTools.jl")
include("ConstGateGen.jl")
