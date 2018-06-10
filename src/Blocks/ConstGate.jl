export ConstantGate
abstract type ConstantGate{N, T} <: PrimitiveBlock{N, T} end

"""
    @const_gate name[::T] = matrix

Define a new constant gate.
"""
:(@const_gate)

@static if VERSION < v"0.7-"
    include("ConstGateTools.jl")
else
    include("ConstGateTools2.jl")
end

include("ConstGateGen.jl")
