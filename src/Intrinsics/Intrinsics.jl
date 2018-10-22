module Intrinsics

using LinearAlgebra, SparseArrays
using StaticArrays: SVector, SMatrix, SDiagonal
using Base.Cartesian

using LuxurySparse
import ..Yao: nactive, reorder, invorder, reorder

include("Exceptions.jl")

# MathUtils
export batch_normalize!, batch_normalize
export rolldims2!, rolldims!
export hilbertkron, linop2dense, rotmat, general_controlled_gates, general_c1_gates
export rand_unitary, rand_hermitian

include("Math.jl")

# Basis
export DInt, Ints
export basis, bmask, baddrs
export bit_length, log2i, bsizeof
export testall, testany, testval, setbit, flip, neg, swapbits, takebit, breflect
export indices_with, bitarray, packbits, controller
export bint, bfloat, bint_r, bfloat_r
export bdistance
export onehotvec
export hypercubic, reordered_basis, Reorderer, reorder, invorder

include("Basis.jl")

export @assert_addr_safe, @assert_addr_fit, @assert_addr_inbounds, AddressConflictError, QubitMismatchError
export _assert_addr_safe, _assert_addr_fit, _assert_addr_inbounds
include("MacroTools.jl")

include("TupleTools.jl")

import LinearAlgebra: ishermitian
export isunitary, isreflexive, ishermitian, iscommute
include("OperatorTraits.jl")

# Matrices
export swaprows!, mulrow!, matvec, mulcol!, swapcols!, u1rows!, unrows!
export u1mat, unmat, cunmat, setcol!, getcol, unij!
export itercontrol, IterControl, controldo, u1apply!, unapply!, cunapply!
export fidelity_pure, fidelity_mix
include("elementary.jl")
include("IterControl.jl")
include("GeneralApply.jl")
include("GeneralMat.jl")

end
