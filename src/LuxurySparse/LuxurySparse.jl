module LuxurySparse

using Compat
using Compat.LinearAlgebra
using Compat.SparseArrays

import Compat.LinearAlgebra: ishermitian
import Compat.SparseArrays: SparseMatrixCSC, nnz, nonzeros, sparse

export PermMatrix, pmrand, Identity, I

include("Identity.jl")
include("PermMatrix.jl")

include("conversions.jl")
include("arraymath.jl")
include("linalg.jl")
include("kronecker.jl")

end
