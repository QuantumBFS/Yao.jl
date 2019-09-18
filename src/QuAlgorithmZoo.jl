module QuAlgorithmZoo

using LinearAlgebra
using Yao, BitBasis
using YaoExtensions

include("Adam.jl")
include("PhaseEstimation.jl")
include("hamiltonian_solvers.jl")
include("HadamardTest.jl")
include("QSVD.jl")
include("number_theory.jl")

@deprecate random_diff_circuit variational_circuit

end # module
