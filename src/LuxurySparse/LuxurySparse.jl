module LuxurySparse

using Compat
using Compat.LinearAlgebra
using Compat.SparseArrays
using Compat.Random
using StaticArrays: SVector, SMatrix

import Compat: copyto!
import Compat.LinearAlgebra: ishermitian
import Compat.SparseArrays: SparseMatrixCSC, nnz, nonzeros, dropzeros!, findnz
import Base: getindex, size, similar, copy, show

export PermMatrix, pmrand, IMatrix, I, fast_invperm, notdense
export statify, SSparseMatrixCSC, SDiagonal

include("Core.jl")
include("IMatrix.jl")
include("PermMatrix.jl")

include("conversions.jl")
include("promotions.jl")
include("statify.jl")
include("arraymath.jl")
include("linalg.jl")
include("kronecker.jl")

end
