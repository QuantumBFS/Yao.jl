using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays


@testset "default register" begin
    include("Default.jl")
end
