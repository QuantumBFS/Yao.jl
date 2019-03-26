export ConstGate,
    @const_gate, ConstantGate,
    X, Y, Z, H, I2,
    XGate, YGate, ZGate, HGate, I2Gate

"""
    ConstGate

A module contains all constant gate definitions.
"""
module ConstGate
import ..YaoBlockTree
export ConstantGate, PauliGate

"""
    ConstantGate{N, T} <: PrimitiveBlock{N, T}

Abstract type for constant gates. Constant gates are
quantum gates with constant value, e.g Pauli gates,
T gate, Hadmard gates, etc.
"""
abstract type ConstantGate{N, T} <: YaoBlockTree.PrimitiveBlock{N, T} end

include("const_gate_tools.jl")
include("const_gate_gen.jl")

const PauliGate{T} = Union{I2Gate{T}, XGate{T}, YGate{T}, ZGate{T}}

YaoBlockTree.cache_key(x::ConstantGate) = 0x1

struct IGate{N, T} <: ConstantGate{N, T} end
YaoBlockTree.mat(::IGate{N, T}) where {N, T} = IMatrix{N, T}()

YaoBase.ishermitian(::IGate) = true
YaoBase.isunitary(::IGate) = true
end

# import some frequently-used objects
import .ConstGate:
    XGate, YGate, ZGate, HGate, I2Gate, X, Y, Z, H, I2,
    @const_gate, ConstantGate, PauliGate
