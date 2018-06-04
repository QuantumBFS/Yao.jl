using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao
using Yao.CacheServers

@testset "check cache element" begin
ce = CacheElement(SparseMatrixCSC{ComplexF64, Int}, unsigned(2))
g = kron(3, X(), phase(0.1), Rx(0.1))
push!(ce, g, mat(g), unsigned(1)) # do nothing
@test_throws KeyError pull(ce, g)

push!(ce, g, mat(g), unsigned(3))
@test pull(ce, g) == mat(g)

empty!(ce)
@test_throws KeyError pull(ce, g)
end

@testset "set level" begin
ce = CacheElement(SparseMatrixCSC{ComplexF64, Int}, unsigned(2))
setlevel!(ce, unsigned(3))
@test ce.level == unsigned(3)
end
