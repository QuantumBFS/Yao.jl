module AD

using BitBasis, YaoArrayRegister, YaoBase
using ..YaoBlocks

using SparseArrays, LuxurySparse, LinearAlgebra

include("patches.jl")
include("NoParams.jl")
include("outerproduct_and_projection.jl")
include("adjroutines.jl")
include("mat_back.jl")
include("apply_back.jl")
include("gradcheck.jl")

end
