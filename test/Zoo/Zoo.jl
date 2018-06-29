using Yao
using Yao.Zoo
using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays


@testset "QFT" begin
    include("QFT.jl")
end

@testset "Differential" begin
    include("Differential.jl")
end

@testset "RotBasis" begin
    include("RotBasis.jl")
end
