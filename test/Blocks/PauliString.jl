using Test, Random, LinearAlgebra, SparseArrays

using Yao
using Yao.Blocks
using Yao.Blocks: cache_key

@testset "paulistring" begin
    ps = PauliString(PauliGate{ComplexF64}[X, X, Y, X, Z])
    kr = kron(5, X, X, Y, X, Z)
    println(kr)
    reg = rand_state(5)
    @test copy(reg) |> ps ≈ copy(reg) |> kr
    @test mat(ps) ≈ mat(kr)

    ps[3] = I2
    kr[3] = I2
    @test usedbits(ps) == [1,2,4,5]
    @test addrs(ps) == [1,2,3,4,5]
    @test mat(ps) ≈ mat(kr)
    psc = copy(ps)
    @test ps == psc
    @test ps !== copy(psc)

    @test ishermitian(ps) == ishermitian(mat(ps))
    @test isunitary(ps) == isunitary((mat(ps)))
    @test isreflexive(ps) == isreflexive(mat(ps))
    @test length(ps) == 5

    @test hash(ps) != hash(psc)
    @test cache_key(ps) == cache_key(psc)
    println(ps)
end

