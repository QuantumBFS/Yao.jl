using Test, Random, LinearAlgebra, SparseArrays

using YaoBase, YaoBlockTree, YaoDenseRegister
using YaoBase.Math: linop2dense

@testset "constructor" begin
    g = Roller(X, kron(2, X, Y), Z, Z)
    @test isa(g, Roller{5, ComplexF64})
    @test usedbits(g) == [1:5...]
    @test addrs(g) == [1, 2, 4, 5]

    src = phase(0.1)
    g = Roller{4}(src)
    g.blocks[1].theta = 0.2
    @test src.theta == 0.1
    @test g.blocks[2].theta == 0.1
    blks = [X, Y, kron(3, 2=>Rx(0.3))]
    @test all(chsubblocks(g, blks) |> subblocks .== blks)
end

@testset "copy" begin
    g = Roller{4}(phase(0.1))
    cg = copy(g)

    cg.blocks[1].theta = 1.0
    @test g.blocks[1].theta == 1.0
end

@testset "setindex" begin
    g = Roller{4}(phase(0.1))
    @test_throws MethodError g.blocks[1] = X
end

@testset "iteration" begin
    g = Roller{5}(phase(0.1))
    for each in g.blocks
        @test each.theta == 0.1
    end

    g = Roller(X, kron(2, X, Y), Z, Z)
    list = [X, kron(2, X, Y), Z, Z]
    for (src, tg) in zip(g.blocks, list)
        @test src == tg
    end

    for i in eachindex(g.blocks)
        @test g.blocks[i] == list[i]
    end
end

@testset "tile one block" begin
g = Roller{5}(X)
@test state(apply!(product_state(5, 0b11111), g)) ≈ state(product_state(5, 0b00000))
@test state(apply!(product_state(5, 0b11111, 3), g)) ≈ state(product_state(5, 0b00000, 3))
end

@testset "roll multiple blocks" begin
g = Roller((X, Y, Z, X, X))
tg = kron(5, X, Y, Z, X, X)
@test state(apply!(product_state(5, 0b11111), g)) ≈ state(apply!(product_state(5, 0b11111), tg))
@test state(apply!(product_state(5, 0b11111, 3), g)) ≈ state(apply!(product_state(5, 0b11111, 3), tg))
end

@testset "matrix" begin
    g = Roller((X, kron(2, Y, Z), X, X))
    tg = kron(5, X, Y, Z, X, X)
    @test mat(g) == mat(tg)
    @test linop2dense(r->apply!(DenseRegister(r), g) |> statevec, 5) ≈ mat(tg)


    ⊗ = kron
    U = mat(X)
    U2 = mat(CNOT)
    id = mat(I2)
    m = U2 ⊗ id ⊗ U ⊗ id
    r = roll(5, I2, X, I2, CNOT)
    @test m == mat(r)
end

@testset "traits" begin
g = Roller(X, kron(2, X, Y), Z, Z)
@test isunitary(g) == true
@test isreflexive(g) == true
@test ishermitian(g) == true
end
