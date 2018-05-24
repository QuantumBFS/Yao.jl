using Compat.Test

@testset "chain block" include("ChainBlock.jl")
@testset "kron block" include("KronBlock.jl")
@testset "control block" include("Control.jl")
@testset "roller block" include("Roller.jl")
