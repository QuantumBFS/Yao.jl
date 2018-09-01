using Test, Random, LinearAlgebra, SparseArrays

using Yao
using Yao.Intrinsics
using Yao.Intrinsics: group_shift, itercontrol, controldo, IterControl, lmove
using LuxurySparse

@testset "private functions: group_shift and lmove" begin
    @test group_shift(5, [1,2,5]) == ([0, 15], [2, 1])
    @test group_shift(5, [2,3]) == ([1], [2])
    @test group_shift(5, [1,3,5]) == ([0, 3, 15], [1, 1, 1])

    @test string(lmove(5, 1, 2), base=2) == "10001"
end

@testset "iterator interface" begin
    v = randn(ComplexF64, 1<<4)
    it = itercontrol(4, [3],[1])
    vec = Int[]
    it2 = itercontrol(4, [3, 4], [0, 0])
    for i in it2
        push!(vec, i)
    end
    @test vec == [0,1,2,3]

    vec = Int[]
    it4 = itercontrol(4, [4,2, 1], [1, 1, 1])
    for i in it4
        push!(vec, i)
    end
    @test vec == [11, 15]
    @test (rrr=copy(v); controldo(x->mulrow!(rrr, x+1, -1.0), it4); rrr) ≈ mat(control(4, (4,2), 1=>Z)) * v
    nbit = 8
    it = itercontrol(nbit, [3],[1])
    V = randn(ComplexF64, 1<<nbit)
    res = mat(kron(nbit, 3=>X))*V
    @test (rrr=copy(V); controldo(x->swaprows!(rrr, x+1, x-3), it); rrr) ≈ res
    @test (rrr=copy(V); controldo(x->mulrow!(rrr, x+1, -1), itercontrol(nbit, [3,7, 6], [1, 1, 1])); rrr) ≈ mat(control(nbit, (3,7), 6=>Z)) * V
end
