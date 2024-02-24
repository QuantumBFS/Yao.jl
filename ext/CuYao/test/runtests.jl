using CUDA, CuYao, Test
CUDA.allowscalar(false)

@testset "CUDA patch" begin
    include("CUDApatch.jl")
end

@testset "GPU reg" begin
    include("register.jl")
end

@testset "gpu applies" begin
    include("instructs.jl")
end

@testset "extra" begin
    include("extra.jl")
end