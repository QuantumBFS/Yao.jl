using Test, YaoBlocks, YaoArrayRegister

@testset "basic" begin
    reg = rand_state(10)
    block = kron(4, 2 => X)
    c = subroutine(10, block, [1, 3, 9, 2])
    @test nqubits(c) == 10
    @test nactive(c) == 4
    @test isunitary(c) == true
    @test isreflexive(c) == true
    @test ishermitian(c) == true
    blk = kron(4, 2 => Rx(0.3))
    @test chsubblocks(c, [blk]) |> subblocks |> first == blk
    @test occupied_locs(c) == (3,)

    @test apply!(copy(reg), c) == apply!(copy(reg), kron(10, 3 => X))
    @test apply!(rand_state(12, nbatch = 10) |> focus!(Tuple(1:10)...), c) |> nactive == 10
end

@testset "test repeat" begin
    c = subroutine(8, repeat(5, H), 1:5)
    r = rand_state(8)
    r1 = copy(r) |> c
    r2 = copy(r) |> repeat(8, H, 1:5)
    @test r1 ≈ r2
end

@testset "mat" begin
    cc = subroutine(5, kron(X, X), (1, 3))
    @test applymatrix(cc) ≈ mat(cc)
end

@testset "push coverage" begin
    @test subroutine(put(3, 2=>X), (3,4,5))(5) isa Subroutine
    @test subroutine(put(2=>X), (3,4,5))(5) isa Subroutine
    s = subroutine(put(2=>X), (3,4,5))(5)
    q = subroutine(put(3=>Y), (3,4,5))(5)
    z = subroutine(put(3=>Val(im)*X), (3,4,5))(5)
    @test s' == s
    @test iscommute(s', s)
    @test iscommute(s', z)
    @test_throws LocationConflictError subroutine(5, put(3,2=>X), (1,4,2,5))
    @test_throws ErrorException subroutine(5, put(3,2=>X), (7,4,5))
    @test YaoBlocks.PropertyTrait(s) == YaoBlocks.PreserveAll()
end

@testset "instruct_get_element" begin
    for pb in [subroutine(3, Y, (2,)), subroutine(4, matblock(rand_unitary(4)), (4,2))]
        mpb = mat(pb)
        allpass = true
        for i=basis(pb), j=basis(pb)
            allpass &= pb[i, j] == mpb[Int(i)+1, Int(j)+1]
        end
        @test allpass

        allpass = true
        for j=basis(pb)
            allpass &= vec(pb[:, j]) == mpb[:, Int(j)+1]
            allpass &= vec(pb[:, EntryTable([j], [1.0+0im])]) == mpb[:, Int(j)+1]
            allpass &= vec(pb[j, :]) == mpb[Int(j)+1, :]
        end
        @test allpass
    end
end