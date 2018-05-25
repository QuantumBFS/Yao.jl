using Compat.Test

@testset "chain block" begin
    include("ChainBlock.jl")
end

@testset "kron block" begin
    include("KronBlock.jl")
end

@testset "control block" begin
    include("Control.jl")
end

@testset "roller block" begin
    include("Roller.jl")
end
