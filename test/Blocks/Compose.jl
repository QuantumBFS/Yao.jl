using Compat.Test

@testset "kron block" begin
    include("KronBlock.jl")
end

@testset "chain block" begin
    include("ChainBlock.jl")
end