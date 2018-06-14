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
export hilbertkron, linop2dense, rotmat

include("Math.jl")

# Basis
export DInt, Ints, DInts
export basis, bmask
export bit_length, log2i, bsizeof, nqubits
export testall, testany, testval, setbit, flip, neg, swapbits, takebit
export indices_with, bitarray, packbits, controller
export bdistance
export onehotvec
export hypercubic, reorder

include("Basis.jl")

export @assert_addr_safe, @assert_addr_fit, @assert_addr_inbounds, AddressConflictError, QubitMismatchError
export _assert_addr_safe, _assert_addr_fit, _assert_addr_inbounds
include("MacroTools.jl")

include("TupleTools.jl")

import Compat.LinearAlgebra: ishermitian
export isunitary, isreflexive, ishermitian
include("OperatorTraits.jl")

end
