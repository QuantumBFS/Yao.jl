module LuxurySparse

using Compat
using Compat.LinearAlgebra
using Compat.SparseArrays

export PermMatrix, pmrand, Identity, I

"""
    pmrand(T::Type, n::Int) -> PermMatrix

Return random PermMatrix.
"""
function pmrand end

"""
    I(n::Int) = Identity{n}()

Identity matrix.
"""
function I end

include("PermMatrix.jl")
include("Identity.jl")

end
