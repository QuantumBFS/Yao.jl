export ConstantGate, PauliGate

"""
    ConstantGate{N, T} <: PrimitiveBlock{N, T}

Abstract type for constant gates. Constant gates are
quantum gates with constant value, e.g Pauli gates,
T gate, Hadmard gates, etc.
"""
abstract type ConstantGate{N, T} <: PrimitiveBlock{N, T} end

include("const_gate_tools.jl")
include("const_gate_gen.jl")

const PauliGate{T} = Union{I2Gate{T}, XGate{T}, YGate{T}, ZGate{T}}

cache_key(x::ConstantGate) = 0x1
