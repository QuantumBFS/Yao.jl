module Registers

using Random, LinearAlgebra, SparseArrays
using StatsBase
using Lazy
using ..Intrinsics

import Base: length
import Base: eltype, copy, similar, *, join
import Base: show

# import package APIs
import ..Yao: DefaultType, nqubits, nactive, reorder, invorder
import ..Intrinsics: basis, hypercubic

# APIs
export nqubits, nactive, nremain, nbatch, state, statevec, hypercubic, rank3, focus!, relax!, extend!, basis, probs, isnormalized
export AbstractRegister, Register, invorder!, reorder!, addbit!, reset!, ConjRegister

# factories
export register, zero_state, product_state, rand_state, stack, uniform_state

# bit_str
export @bit_str, asindex
export DensityMatrix, density_matrix, ρ
export fidelity, tracedist


include("BitStr.jl")
include("Core.jl")

include("Default.jl")
include("Measure.jl")
include("Focus.jl")

include("DensityMatrix.jl")
# NOTE: these two are not implemented
# include("GPU.jl")
# include("MPS.jl")

end
