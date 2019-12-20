using YaoBlocks.AD, YaoBlocks
using Test

@testset "patches" begin
    include("patches.jl")
end

@testset "outerproduct_and_projection" begin
    include("outerproduct_and_projection.jl")
end

@testset "NoParams" begin
    include("NoParams.jl")
end

@testset "apply_back" begin
    include("apply_back.jl")
end

@testset "mat_back" begin
    include("mat_back.jl")
end

@testset "specializes" begin
    include("specializes.jl")
end
