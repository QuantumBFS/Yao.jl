module LuxurySparse

using Compat
using Compat.LinearAlgebra
using Compat.SparseArrays

export PermMatrix, pmrand, Identity, I

include("PermMatrix.jl")
include("Identity.jl")

end