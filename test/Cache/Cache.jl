using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays


@testset "cache element" begin
    include("CacheElement.jl")
end

@testset "default server" begin
    include("DefaultServer.jl")
end

@testset "cache flag" begin
    include("CacheFlag.jl")
end

@testset "hash rules" begin
    include("HashRules.jl")
end

@testset "cache rules" begin
    include("CacheRules.jl")
end

@testset "update rules" begin
    include("UpdateRules.jl")
end

@testset "empty rules" begin
    include("EmptyRules.jl")
end
