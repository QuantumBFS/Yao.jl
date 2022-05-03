using Test, Random, YaoAPI, YaoBlocks, LuxurySparse
using YaoBlocks.ConstGate

function random_dense_kron(n; gateset)
    locs = randperm(n)
    blocks = [i => rand(gateset) for i in locs]
    g = KronBlock(n, blocks...)
    sorted_blocks = sort(blocks, by = x -> x[1])
    t = mapreduce(x -> mat(x[2]), kron, reverse(sorted_blocks), init = IMatrix(1))
    mat(g) ≈ t || @info(g)
end

function rand_kron_test(n; gateset)
    firstn = rand(1:n)
    locs = randperm(n)
    blocks = [rand(gateset) for i = 1:firstn]
    seq = [i => each for (i, each) in zip(locs[1:firstn], blocks)]
    mats = Any[i => mat(each) for (i, each) in zip(locs[1:firstn], blocks)]
    append!(mats, [i => IMatrix(2) for i in locs[firstn+1:end]])
    sorted = sort(mats, by = x -> x.first)
    mats = map(x -> x.second, reverse(sorted))

    g = KronBlock(n, seq...)
    t = reduce(kron, mats, init = IMatrix(1))
    mat(g) ≈ t || @info(g)
end


@testset "test constructors" begin
    @test_throws LocationConflictError KronBlock(5, 4 => CNOT, 5 => X)
    @test_throws MethodError kron(3, 1 => X, Y)
    @test kron(2 => X)(4) == kron(4, 2 => X)
    @test_throws LocationConflictError kron(10, (2, 3) => CNOT, [3] => Y)
    @test kron(10, (2, 3) => CNOT, [5] => Y) isa KronBlock
    @test_throws ErrorException kron(5, (5, 3) => CNOT, [3] => Y)
end

@testset "test mat" begin
    TestGateSet =
        [X, Y, Z, phase(0.1), phase(0.2), phase(0.3), rot(X, 0.1), rot(Y, 0.4), rot(Z, 0.2)]

    U = Const.X
    U2 = Const.CNOT

    @testset "case 1" begin
        m = kron(Const.I2, U)
        g = kron(2, 1 => X)
        @test m == mat(g)

        m = kron(U, Const.I2)
        g = kron(2, 2 => X)
        @test m == mat(g)
        @test occupied_locs(g) == (2,)
        @test occupied_locs(kron(5, 3=>X, 4=>Y)) == (3, 4)
        @test occupied_locs(kron(5, 3=>X, 4=>I2)) == (3,)
        blks = [Rx(0.3)]
        @test chsubblocks(g, blks) |> subblocks |> collect == blks

        m = kron(U2, Const.I2, U, Const.I2)
        @test_throws LocationConflictError KronBlock(5, 4 => CNOT, 2 => X)
        g = KronBlock(5, 4:5 => CNOT, 2 => X)
        @test m == mat(g)
        @test g.locs == (2:2, 4:5)
        @test occupied_locs(g) == (2, 4, 5)
    end

    @testset "case 2" begin
        m = kron(mat(X), mat(Y), mat(Z))
        g = KronBlock(3, 1 => Z, 2 => Y, 3 => X)
        g1 = KronBlock(Z, Y, X)
        @test m == mat(g)
        @test m == mat(g1)

        m = kron(Const.I2, m)
        g = KronBlock(4, 1 => Z, 2 => Y, 3 => X)
        @test m == mat(g)
    end

    @testset "random dense sequence, n=$i" for i = 2:8
        @test random_dense_kron(i; gateset = TestGateSet)
    end

    @testset "random mat sequence, n=$i" for i = 4:8
        @test rand_kron_test(i; gateset = TestGateSet)
    end
end

@testset "test allocation" begin
    g = kron(4, 1 => X, 2 => phase(0.1))

    # copy
    cg = copy(g)
    cg[2].theta = 0.2
    @test g[2].theta == 0.1
    @test cg[2].theta == 0.2

    @test cache_key(cg) != cache_key(g)
end

@testset "test iteration" begin
    g = kron(5, 1 => X, 3 => Y, 4 => rot(X, 0.0), 5 => rot(Y, 0.0))
    for (src, tg) in zip(g, [1:1 => X, 3:3 => Y, 4:4 => rot(X, 0.0), 5:5 => rot(Y, 0.0)])
        @test src[1] == tg[1]
        @test src[2] == tg[2]
    end

    for (src, tg) in zip(eachindex(g), [1:1, 3:3, 4:4, 5:5])
        @test src == tg
    end
end

@testset "test inspect" begin
    g = kron(5, 1 => X, 3 => Y, 4 => rot(X, 0.0), 5 => rot(Y, 0.0))
    collect(subblocks(g)) === g.blocks
    eltype(g) == Tuple{Int,AbstractBlock}

    @test isunitary(g) == true
    @test isreflexive(g) == true
end

@testset "empty kron" begin
    T = Float64
    @test mat(T, kron(5)) === mat(T, chain(5)) == IMatrix{1 << 5,Float64}()
end

@testset "getindex2" begin
    pb = kron(5, 2=>Y, 3=>X)
    mpb = mat(pb)
    allpass = true
    for i=basis(pb), j=basis(pb)
        allpass &= pb[i, j] == mpb[Int(i)+1, Int(j)+1]
    end
    @test allpass
    pb = kron(5, 2:3=>matblock(rand_unitary(4)), 4=>X)
    mpb = mat(pb)
    allpass = true
    for i=basis(pb), j=basis(pb)
        allpass &= pb[i, j] == mpb[Int(i)+1, Int(j)+1]
    end
    @test allpass
end