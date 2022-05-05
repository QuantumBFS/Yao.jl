using Test, YaoBlocks, YaoArrayRegister
using YaoBlocks.ConstGate
using SparseArrays
using LinearAlgebra

@testset "construct" begin
    @test_throws AssertionError put(2, 1 => swap(2, 1, 2))
end

@testset "apply!" begin
    n = 6
    Reg = rand_state(n)

    pb = PutBlock(n, X, (3,))
    @test copy(pb) == pb
    rb = repeat(n, X, (3,))
    @test apply!(copy(Reg), pb) ≈ apply!(copy(Reg), rb)
    @test pb |> applymatrix ≈ mat(pb)
    pb = PutBlock(n, rot(X, 0.3), (3,))
    @test pb |> applymatrix ≈ mat(pb)

    pb = PutBlock(n, rot(CNOT, 0.3), (6, 3))
    @test pb |> applymatrix ≈ mat(pb)
    pb = PutBlock(n, matblock(mat(rot(CNOT, 0.3)) |> Matrix), (6, 3))
    @test pb |> applymatrix ≈ mat(pb)

    pb = PutBlock(n, rot(X, 0.3), (3,))
    @test pb |> applymatrix ≈ mat(pb)
    pb = PutBlock(n, matblock(mat(rot(X, 0.3)) |> Matrix), (3,))
    @test pb |> applymatrix ≈ mat(pb)

    Cb = control(n, (3,), 5 => X)
    pb = PutBlock(n, CNOT, (3, 5))
    @test apply!(copy(Reg), Cb) ≈ apply!(copy(Reg), pb)

    blks = [control(2, 1, 2 => Z)]
    @test (chsubblocks(pb, blks) |> subblocks .== blks) |> all

    pb = PutBlock(1000, X, (3,))
    @test pb |> ishermitian
    @test pb |> isunitary
    @test pb |> isreflexive

    @test_throws QubitMismatchError apply!(rand_state(4), put(1000, 2 => Rx(0.4)))
    @test_throws MethodError apply!(rand_state(4), put(4, 2 => matblock(randn(3,3); nlevel=3)))
end

@testset "test swap gate" begin
    include("swap_gate.jl")
end

@testset "rotation gate" begin
    reg = rand_state(5)
    @test apply!(copy(reg), put(5, 2 => Rx(0.3))) |> state ≈
          mat(put(5, 2 => Rx(0.3))) * reg.state
    @test apply!(copy(reg), put(5, 2 => Ry(0.3))) |> state ≈
          mat(put(5, 2 => Ry(0.3))) * reg.state
    @test apply!(copy(reg), put(5, 2 => Rz(0.3))) |> state ≈
          mat(put(5, 2 => Rz(0.3))) * reg.state
end

@testset "operators" begin
    @test size(mat(put(2,1=>matblock(rand_unitary(3); nlevel=3)))) == (9, 9)
    @test size(mat(repeat(2,matblock(rand_unitary(3); nlevel=3)))) == (9, 9)
end

@testset "put matrix" begin
    u = sparse(randn(ComplexF64, 2, 2))
    m1 = mat(put(10, (4,)=>matblock(u)))
    m2 = invoke(YaoBlocks.unmat, Tuple{Val,Int,AbstractMatrix,NTuple}, Val{2}(), 10, u, (4,))
    @test m1 ≈ m2

    u = sparse(randn(ComplexF64, 4, 4))
    m1 = mat(put(10, (2,4)=>matblock(u)))
    m2 = invoke(YaoBlocks.unmat, Tuple{Val,Int,AbstractMatrix,NTuple}, Val{2}(), 10, u, (2,4))
    @test nnz(m1) == nnz(m2)
    @test m1 ≈ m2

    u = randn(ComplexF64, 8, 8)
    m1 = mat(put(10, (4,2,9)=>matblock(u)))
    m2 = invoke(YaoBlocks.unmat, Tuple{Val,Int,AbstractMatrix,NTuple}, Val{2}(), 10, u, (4,2,9))
    @test m1 ≈ m2

    RP1 = matblock(rand_unitary(3); nlevel=3)
    RNr = matblock(rand_unitary(3); nlevel=3)
    @test mat(put(5, 2=>RP1)) ≈ kron(Matrix(I,27,27), mat(RP1), Matrix(I, 3,3))
    @test mat(put(5, (2,3)=>kron(RNr,RP1))) ≈ kron(Matrix(I,9,9), mat(RP1), mat(RNr), Matrix(I, 3,3))

    # corner case, single qubit gate
    @test mat(put(1, 1=>RP1)) ≈ mat(RP1)
end

@testset "instruct_get_element" begin
    for pb in [put(3, 2=>Y), put(4, (4,2)=>matblock(rand_unitary(9); nlevel=3))]
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
            allpass &= vec(pb[j,:]) == mpb[Int(j)+1,:]
            allpass &= vec(pb[EntryTable([j], [1.0+0im]),:]) == mpb[Int(j)+1,:]
            allpass &= isclean(pb[:,j])
        end
        @test allpass
    end
end