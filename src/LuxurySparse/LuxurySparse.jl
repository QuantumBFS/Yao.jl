module LuxurySparse

using Compat
using Compat.LinearAlgebra
using Compat.SparseArrays
using Compat.Random

import Compat: copyto!
import Compat.LinearAlgebra: ishermitian
import Compat.SparseArrays: SparseMatrixCSC, nnz, nonzeros, dropzeros!
import Base: getindex, size, similar, copy, show

export PermMatrix, pmrand, IMatrix, I, fast_invperm, notdense

include("Core.jl")
include("IMatrix.jl")
include("PermMatrix.jl")

include("conversions.jl")
include("promotions.jl")
include("arraymath.jl")
include("linalg.jl")
include("kronecker.jl")

end
