using Test, Yao.EasyBuild

@testset "block_extension" begin
    include("block_extension/blocks.jl")
end

@testset "variational_circuit" begin
    include("variational_circuit.jl")
end

@testset "hamiltonians" begin
    include("hamiltonians.jl")
end

@testset "supremacy_circuit" begin
    include("supremacy_circuit.jl")
end

@testset "google53" begin
    include("google53.jl")
end

@testset "general_U4" begin
    include("general_U4.jl")
end
