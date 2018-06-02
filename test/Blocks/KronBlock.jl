using Compat
using Compat.Test
using Compat.Random
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao
using Yao.Blocks

import Yao.LuxurySparse: I

@testset "constructor" begin
@info "TODO: custom error exception"
@test_throws MethodError KronBlock{2}(1=>X, [2, Y])
end

@testset "check mat" begin

GateSet = [
    X, Y, Z,
    phase(0.1), phase(0.2), phase(0.3),
    rot(X, 0.1), rot(Y, 0.4), rot(Z, 0.2)
]

⊗ = kron
U = mat(X)
id = I(2)

@testset "case 1" begin
    m = id ⊗ U
    g = KronBlock{2}(1=>X)
    @test m == mat(g)

    m = U ⊗ id
    g = KronBlock{2}(2=>X)
    @test m == mat(g)
end

@testset "case 2" begin
    m = mat(X) ⊗ mat(Y) ⊗ mat(Z)
    g = KronBlock{3}(1=>Z, 2=>Y, 3=>X)
    @test m == mat(g)

    m = id ⊗ m
    g = KronBlock{4}(1=>Z, 2=>Y, 3=>X)
    @test m == mat(g)
end

@testset "random dense sequence" begin

function random_dense_kron(n)
    addrs = randperm(n)
    blocks = [i=>rand(GateSet) for i in addrs]
    g = KronBlock{n}(blocks...)
    sorted_blocks = sort(blocks, by=x->x[1])
    t = mapreduce(x->mat(x[2]), kron, I(1), reverse(sorted_blocks))
    mat(g) ≈ t || @info(g)
end

    for i = 2:8
        @test random_dense_kron(i)
    end
end

@testset "random mat sequence" begin

function rand_kron_test(n)
    firstn = rand(1:n)
    addrs = randperm(n)
    blocks = [rand(GateSet) for i = 1:firstn]
    seq = [i=>each for (i, each) in zip(addrs[1:firstn], blocks)]
    mats = [i=>mat(each) for (i, each) in zip(addrs[1:firstn], blocks)]
    append!(mats, [i=>I(2) for i in addrs[firstn+1:end]])
    sorted = sort(mats, by=x->x.first)
    mats = map(x->x.second, reverse(sorted))

    g = KronBlock{n}(seq...)
    t = reduce(kron, I(1), mats)
    mat(g) ≈ t || @info(g)
end

for i = 4:8
    @test rand_kron_test(i)
end

end

end # check mat

@testset "allocation" begin
    g = KronBlock{4}(X, phase(0.1))
    cg = copy(g)
    cg[2].theta = 0.2

    @test g[2].theta == 0.1

    sg = similar(g)
    @test_throws KeyError sg[2]
    @test_throws KeyError sg[1]
end

@testset "insertion" begin

    g = KronBlock{4}(X, phase(0.1))
    g[4] = rot(X, 0.2)
    @test g[4].theta == 0.2

    g[2] = Y
    @test mat(g[2]) == mat(Y)

end

@testset "iteration" begin
    g = KronBlock{5}(X, 3=>Y, rot(X), rot(Y))
    for (src, tg) in zip(g, [1=>X, 3=>Y, 4=>rot(X), 5=>rot(Y)])
        @test src[1] == tg[1]
        @test src[2] == tg[2]
    end

    for (src, tg) in zip(eachindex(g), [1, 3, 4, 5])
        @test src == tg
    end
end

@testset "check traits" begin
    @info "TODO: define traits for primitive blocks"
    g = KronBlock{5}(X, 3=>Y, rot(X), rot(Y))
    addrs(g) === g.addrs
    blocks(g) === g.blocks
    eltype(g) == Tuple{Int, MatrixBlock}

    @test isunitary(g) == true
    @test ispure(g) == true
    @test isreflexive(g) == true
end
