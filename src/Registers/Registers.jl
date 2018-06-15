module Registers

using Compat
using Compat.Random
using Compat.LinearAlgebra
using Compat.SparseArrays
using StatsBase
using ..Intrinsics

import Base: length
import Base: eltype, copy, similar, *
import Base: show

# import package APIs
import ..Yao: DefaultType, nqubits, nactive, reorder, invorder
import ..Intrinsics: basis, hypercubic

# APIs
export nqubits, nactive, nremain, nbatch, state, statevec, hypercubic, focus!, relax!, focuspair!, extend!, basis, probs, isnormalized
export AbstractRegister, Register, Focus, reorder, invorder, stack

# factories
export register, zero_state, rand_state, randn_state

# bit_str
export @bit_str, asindex


include("BitStr.jl")
include("Core.jl")
include("Measure.jl")

include("Default.jl")
include("Focus.jl")
include("reorder.jl")

# NOTE: these two are not implemented
# include("GPU.jl")
# include("MPS.jl")

end
