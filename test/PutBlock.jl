using Test, Random, LinearAlgebra, SparseArrays

using YaoBase, YaoBlockTree
using YaoBlockTree: PutBlock

@testset "apply!" begin
    nbit = 6
    Reg = rand_state(nbit)

    pb = PutBlock{nbit}(X, (3,))
    rb = repeat(nbit, X, (3,))
    @test apply!(copy(Reg), pb) ≈ apply!(copy(Reg), rb)
    @test pb |> applymatrix ≈ mat(pb)
    pb = PutBlock{nbit}(rot(X, 0.3), (3,))
    @test pb |> applymatrix ≈ mat(pb)

    pb = PutBlock{nbit}(rot(CNOT, 0.3), (6, 3))
    @test pb |> applymatrix ≈ mat(pb)
    pb = PutBlock{nbit}(matrixgate(mat(rot(CNOT, 0.3))|>Matrix), (6, 3))
    @test pb |> applymatrix ≈ mat(pb)

    Cb = control(nbit, (3,), 5=>X)
    pb = PutBlock{nbit}(CNOT, (3, 5))
    @test apply!(copy(Reg), Cb) ≈ apply!(copy(Reg), pb)

    blks = [control(2, 1, 2=>Z)]
    @test (chsubblocks(pb, blks) |> subblocks .== blks) |> all

    pb = PutBlock{nbit}(Rx(0.1), (3,))
    @test setiparameters!(copy(pb)) == pb
    @test setiparameters!(copy(pb), :random) == pb
    @test setiparameters!(copy(pb), :zero) == pb

    pb = PutBlock{1000}(X, (3,))
    @test pb |> ishermitian
    @test pb |> isunitary
    @test pb |> isreflexive
end

@testset "dispatch!" begin
    nbit = 6
    pb = PutBlock{nbit}(rot(CNOT, 0.5), (3, 4))
    dispatch!(pb, [0.1])
    @test collect(parameters(pb))[] ≈ 0.1
    dispatch!(+, pb, [0.1])
    @test collect(parameters(pb))[] ≈ 0.2
    @test addrs(pb) == (3,4)
    @test usedbits(pb) == [3,4]
    @test block(copy(pb)) === pb.block
    @test hash(copy(pb)) != hash(pb)
    @test copy(pb) == pb
    println(pb)
end
