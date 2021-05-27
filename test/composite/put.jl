using Test, YaoBlocks, YaoArrayRegister
using YaoBlocks.ConstGate

@testset "construct" begin
    @test_throws AssertionError put(2, 1 => swap(2, 1, 2))
end

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
    pb = PutBlock{n}(matblock(mat(rot(CNOT, 0.3)) |> Matrix), (6, 3))
    @test pb |> applymatrix ≈ mat(pb)

    pb = PutBlock{n}(rot(X, 0.3), (3,))
    @test pb |> applymatrix ≈ mat(pb)
    pb = PutBlock{n}(matblock(mat(rot(X, 0.3)) |> Matrix), (3,))
    @test pb |> applymatrix ≈ mat(pb)

    Cb = control(n, (3,), 5 => X)
    pb = PutBlock{n}(CNOT, (3, 5))
    @test apply!(copy(Reg), Cb) ≈ apply!(copy(Reg), pb)

    blks = [control(2, 1, 2 => Z)]
    @test (chsubblocks(pb, blks) |> subblocks .== blks) |> all

    pb = PutBlock{1000}(X, (3,))
    @test pb |> ishermitian
    @test pb |> isunitary
    @test pb |> isreflexive

    @test_throws QubitMismatchError apply!(rand_state(4), put(1000, 2 => Rx(0.4)))
end

@testset "test swap gate" begin
    include("swap_gate.jl")
end

@testset "rotation gate" begin
    reg = rand_state(5)
    @test apply!(copy(reg), put(5, 2 => Rx(0.3))) |> state ≈ mat(put(5, 2 => Rx(0.3))) * reg.state
    @test apply!(copy(reg), put(5, 2 => Ry(0.3))) |> state ≈ mat(put(5, 2 => Ry(0.3))) * reg.state
    @test apply!(copy(reg), put(5, 2 => Rz(0.3))) |> state ≈ mat(put(5, 2 => Rz(0.3))) * reg.state
end
