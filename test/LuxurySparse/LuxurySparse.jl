using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

@testset "Identity" begin
    include("Identity.jl")
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
