using Compat.Test
using QuCircuit
import QuCircuit: CacheElement, setlevel!

@testset "check cache element" begin
ce = CacheElement(SparseMatrixCSC{Complex128, Int}, unsigned(2))
g = kron(3, X(), phase(0.1), Rx(0.1))
push!(ce, g, sparse(g), unsigned(1)) # do nothing
@test_throws KeyError pull(ce, g)

push!(ce, g, sparse(g), unsigned(3))
@test pull(ce, g) == sparse(g)

empty!(ce)
@test_throws KeyError pull(ce, g)
end

@testset "set level" begin
ce = CacheElement(SparseMatrixCSC{Complex128, Int}, unsigned(2))
setlevel!(ce, unsigned(3))
@test ce.level == unsigned(3)
end
