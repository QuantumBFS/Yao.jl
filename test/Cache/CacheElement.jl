using Compat.Test
import QuCircuit: CacheElement, X, phase, rot, pull

@testset "constructor" begin
end

@testset "check cache element" begin
    ce = CacheElement(SparseMatrixCSC{Complex128, Int}, unsigned(2))
    g = kron(3, X(), phase(0.1), rot(:X, 0.1))
    push!(ce, g, sparse(g), unsigned(1)) # do nothing
    @test_throws KeyError pull(ce, g)

    push!(ce, g, sparse(g), unsigned(3))
    @test pull(ce, g) == sparse(g)
end
