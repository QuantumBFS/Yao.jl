module LuxurySparse

using Compat
using Compat.LinearAlgebra
using Compat.SparseArrays
using Compat.Random

import Compat: copyto!
import Compat.LinearAlgebra: ishermitian
import Compat.SparseArrays: SparseMatrixCSC, nnz, nonzeros, dropzeros!
import Base: getindex, size, similar, copy, show

export PermMatrix, pmrand, IMatrix, I, fast_invperm

function fast_invperm(order)
    v = similar(order)
    @inbounds @simd for i=1:length(order)
        v[order[i]] = i
    end
    v
end

dropzeros!(A::Diagonal) = A

include("IMatrix.jl")
include("PermMatrix.jl")

include("conversions.jl")
include("promotions.jl")
include("arraymath.jl")
include("linalg.jl")
include("kronecker.jl")

end
