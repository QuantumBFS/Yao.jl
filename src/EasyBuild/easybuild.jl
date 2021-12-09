module EasyBuild
using YaoBlocks, YaoBlocks.LuxurySparse, YaoBlocks.YaoAPI, YaoBlocks.YaoArrayRegister
using YaoBlocks.LinearAlgebra
include("block_extension/blocks.jl")
include("general_U4.jl")
include("qft_circuit.jl")
include("hamiltonians.jl")
include("variational_circuit.jl")
include("supremacy_circuit.jl")
include("google53.jl")
include("hadamardtest.jl")
end