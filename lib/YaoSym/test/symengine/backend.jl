using Test

@testset "blocks" begin
    include("blocks.jl")
end

@testset "register" begin
    include("register.jl")
end

@testset "instruct" begin
    include("instruct.jl")
end
