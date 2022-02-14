using Test, YaoBlocks, YaoArrayRegister, LuxurySparse, CacheServers

@testset "constructor" begin
    @test CacheFragment(X) isa CacheFragment{XGate,UInt8,Any}
    @test CacheFragment{XGate,Int,PermMatrix{ComplexF64,Int}}(X) isa
          CacheFragment{XGate,Int,PermMatrix{ComplexF64,Int}}
    @test CacheFragment{XGate,Int}(X) isa CacheFragment{XGate,Int,Any}
end

@testset "CacheServer API" begin
    frag = CacheFragment(X)
    @test update!(frag, mat(X)) === frag
    @test pull(frag) == mat(X)
    clear!(frag)
    @test_throws KeyError pull(frag)
end

test_server = DefaultServer{AbstractBlock,CacheFragment}()

@testset "constructor" begin
    c = CachedBlock(test_server, X, 2)
    @test c isa CachedBlock{DefaultServer{AbstractBlock,CacheFragment},XGate}

    blk = kron(4, 2 => Rx(0.3))
    @test first(chsubblocks(c, blk) |> subblocks) == blk
end

@testset "methods" begin
    g = CachedBlock(test_server, X, 3)
    @test_throws KeyError pull(g)

    update_cache(ComplexF64, g)
    @test pull(g) ≈ mat(X)

    clear!(g)
    @test_throws KeyError pull(g)

    @test mat(g) ≈ mat(X)

    clear!(g)

    @test state(apply!(arrayreg(bit"1"), g)) ≈ state(arrayreg(bit"0"))
    @test pull(g) ≈ mat(X)

    clear!(g)
    @test state(YaoBlocks._apply!(arrayreg(bit"1"), g, 2)) ≈ state(arrayreg(bit"0"))
    @test_throws KeyError pull(g)
end

@testset "direct inherited methods" begin
    g = chain([X, Z, Y, I2])
    g = CachedBlock(test_server, g, 2)

    @test g[1] isa XGate
    @test g[3] isa YGate

    g[4] = Z
    @test g[4] isa ZGate

    g = chain(X, Y)
    g = CachedBlock(test_server, g, 2)

    @test g[1] isa XGate
    @test g[2] isa YGate

    #@test iterate(g) == iterate(g.content)
    #@test length(g) == length(g.content)

    @test subblocks(g) == (g.content,)

    gg = chain(g, g)
    cgg = CachedBlock(test_server, gg, 2)
    @test cgg isa CachedBlock
    @test content(cgg)[1] == g
end

@testset "matrix-chain cache" begin
    A = matblock(rand(ComplexF64, 2, 2))
    B = matblock(rand(ComplexF64, 2, 2))
    C = cache(chain(A, B))

    update_cache(ComplexF64, C)
    @test pull(C) ≈ mat(C)
end
