using Test

@testset "register" begin
    include("register.jl")
end

@testset "symengine" begin
    include("symengine/backend.jl")
end
