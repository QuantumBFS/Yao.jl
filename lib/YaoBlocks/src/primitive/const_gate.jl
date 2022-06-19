export @const_gate,
    ConstantGate,
    ConstGate,
    X,
    Y,
    Z,
    H,
    I2,
    SWAP,
    T,
    XGate,
    YGate,
    ZGate,
    HGate,
    I2Gate,
    SWAPGate,
    TGate

"""
    ConstGate

A module contains all constant gate definitions.
"""
module ConstGate
import ..YaoBlocks
using LuxurySparse, YaoAPI, BitBasis
using YaoArrayRegister: logdi
import MLStyle: @match
using SparseArrays, LinearAlgebra

export ConstantGate, PauliGate

"""
    ConstantGate{N, D} <: PrimitiveBlock{N, D}

Abstract type for constant gates. Constant gates are
quantum gates with constant value, e.g Pauli gates,
T gate, Hadmard gates, etc. Type parameter `N` is the number of qubits.
"""
abstract type ConstantGate{N,D} <: YaoBlocks.PrimitiveBlock{D} end

include("const_gate_tools.jl")
include("const_gate_gen.jl")

const PauliGate = Union{I2Gate,XGate,YGate,ZGate}

YaoBlocks.cache_key(x::ConstantGate) = 0x1
end

# import some frequently-used objects
import .ConstGate:
    XGate,
    YGate,
    ZGate,
    HGate,
    I2Gate,
    SWAPGate,
    TGate,
    X,
    Y,
    Z,
    H,
    I2,
    SWAP,
    T,
    @const_gate,
    ConstantGate,
    PauliGate

occupied_locs(::I2Gate) = ()
nqudits(::ConstantGate{N}) where N = N

function unsafe_getindex(::Type{T}, rg::XGate, i::Integer, j::Integer) where {T}
    i==j ? zero(T) : one(T)
end
function unsafe_getindex(::Type{T}, rg::YGate, i::Integer, j::Integer) where {T}
    if i==j
        zero(T)
    elseif i > j
        T(im)
    else
        T(-im)
    end
end
function unsafe_getindex(::Type{T}, rg::ZGate, i::Integer, j::Integer) where {T}
    if i==j
        if i==0
            one(T)
        else
            -one(T)
        end
    else
        zero(T)
    end
end
# NOTE: The above function has no speedup if I specialize `unsafe_getcol`

# NOTE: The following function fixes the problem of having too many entries when get a column.
function unsafe_getcol(::Type{T}, rg::ConstGate.P0Gate, j::DitStr{2}) where {T}
    if iszero(j)
        return [j], [one(T)]
    else
        return typeof(j)[], T[]
    end
end
function unsafe_getcol(::Type{T}, rg::ConstGate.P1Gate, j::DitStr{2}) where {T}
    if iszero(j)
        return typeof(j)[], T[]
    else
        return [j], [one(T)]
    end
end
