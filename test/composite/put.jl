using Test, YaoBlockTree, YaoArrayRegister

@testset "apply!" begin
    n = 6
    Reg = rand_state(n)

    pb = PutBlock{n}(X, (3,))
    rb = repeat(n, X, (3,))
    @test apply!(copy(Reg), pb) ≈ apply!(copy(Reg), rb)
    @test pb |> applymatrix ≈ mat(pb)
    pb = PutBlock{n}(rot(X, 0.3), (3,))
    @test pb |> applymatrix ≈ mat(pb)

    pb = PutBlock{n}(rot(CNOT, 0.3), (6, 3))
    @test pb |> applymatrix ≈ mat(pb)
    pb = PutBlock{n}(matblock(mat(rot(CNOT, 0.3))|>Matrix), (6, 3))
    @test pb |> applymatrix ≈ mat(pb)

    Cb = control(n, (3,), 5=>X)
    pb = PutBlock{n}(CNOT, (3, 5))
    @test apply!(copy(Reg), Cb) ≈ apply!(copy(Reg), pb)

    blks = [control(2, 1, 2=>Z)]
    @test (chsubblocks(pb, blks) |> subblocks .== blks) |> all

    pb = PutBlock{1000}(X, (3,))
    @test pb |> ishermitian
    @test pb |> isunitary
    @test pb |> isreflexive
end
