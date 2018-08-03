using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

@testset "IMatrix" begin
    include("IMatrix.jl")
end

@testset "PermMatrix" begin
    include("PermMatrix.jl")
end

@testset "kronecker" begin
    include("kronecker.jl")
end

@testset "linalg" begin
    include("linalg.jl")
end

@testset "statify" begin
include("statify.jl")
end
