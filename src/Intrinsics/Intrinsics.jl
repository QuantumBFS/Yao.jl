module Intrinsics

using Compat
using Compat.LinearAlgebra
using Compat.SparseArrays

using ..LuxurySparse
import ..LuxurySparse: I
import ..Yao: nqubits

# MathUtils
export batch_normalize!, batch_normalize
export rolldims2!, rolldims!
export hilbertkron

include("Math.jl")

# Basis
export DInt, Ints, DInts
export basis, bmask
export bit_length, log2i, bsizeof, nqubits
export testall, testany, testval, setbit, flip, neg, swapbits, takebit
export indices_with, bitarray, packbits
export bdistance
export onehotvec

include("Basis.jl")

export @assert_addr_safe
include("MacroTools.jl")

include("TupleTools.jl")

end
