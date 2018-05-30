module Registers

using Compat
using Compat.LinearAlgebra
using Compat.SparseArrays

using ..Basis
import ..Yao
import ..Yao: nqubits

export nactive, nremain, nbatch, address, state, statevec, focus!
export AbstractRegister, Register

# factories
export register, zero_state, rand_state, randn_state

import Base: eltype, copy, similar, *
import Base: show


export @bit_str, asindex

struct QuBitStr
    val::UInt
    len::Int
end

import Base: length

# use system interface
asindex(bits::QuBitStr) = bits.val + 1
length(bits::QuBitStr) = bits.len

macro bit_str(str)
    @assert length(str) < 64 "we do not support large integer at the moment"
    val = unsigned(0)
    for (k, each) in enumerate(reverse(str))
        if each == '1'
            val += 1 << (k - 1)
        end
    end
    QuBitStr(val, length(str))
end

import Base: show

function show(io::IO, bitstr::QuBitStr)
    print(io, "QuBitStr(", bitstr.val, ", ", bitstr.len, ")")
end

include("docs.jl")
include("Core.jl")
include("Default.jl")

# NOTE: these two are not implemented
include("GPU.jl")
include("MPS.jl")

end