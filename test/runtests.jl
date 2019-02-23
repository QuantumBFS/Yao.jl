using Test, YaoBase

@testset "test exceptions"
    include("exceptions.jl")
end

@testset "test abstract interface" begin
    include("abstract_register.jl")
end

@testset "test math" begin
    include("math.jl")
end
