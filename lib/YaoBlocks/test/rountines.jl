using Test, YaoBlocks, LuxurySparse, YaoAPI
using YaoBlocks.ConstGate
import YaoBlocks: u1mat, unmat, cunmat, unij!
using YaoArrayRegister

@testset "dense-u1mat-unmat" begin
    nbit = 4
    mmm = Rx(0.5) |> mat
    m1 = u1mat(nbit, mmm, 2)
    m2 = YaoArrayRegister.linop2dense(v -> instruct!(Val(2), v, mmm, (2,)), nbit)
    m3 = unmat(Val(2), nbit, mmm, (2,))
    @test m1 ≈ m2
    @test m1 ≈ m3

    # test control not
    ⊗ = kron
    res = mat(I2) ⊗ mat(I2) ⊗ mat(P1) ⊗ mat(I2) + mat(I2) ⊗ mat(I2) ⊗ mat(P0) ⊗ mat(Rx(0.5))
    m3 = cunmat(nbit, (2,), (0,), mmm, (1,))
    @test m3 ≈ res
end

@testset "sparse-u1mat-unmat" begin
    nbit = 4
    # test control not
    ⊗ = kron
    res = mat(I2) ⊗ mat(I2) ⊗ mat(P1) ⊗ mat(I2) + mat(I2) ⊗ mat(I2) ⊗ mat(P0) ⊗ mat(P1)
    m3 = cunmat(nbit, (2,), (0,), mat(P1), (1,))
    @test m3 ≈ res
    # cunmat fallback
    m4 = cunmat(nbit, (2,), (0,), view(mat(P1), :,:), (1,))
    @test m4 ≈ res
end

@testset "perm-unij-unmat" begin
    perm = PermMatrix([1, 2, 3, 4], [1, 1, 1, 1.0])
    pm = unij!(copy(perm), [2, 3, 4], PermMatrix([3, 1, 2], [0.1, 0.2, 0.3]))
    @test pm ≈ PermMatrix([1, 4, 2, 3], [1, 0.1, 0.2, 0.3])
    pm = unij!(copy(perm), [2, 3, 4], PermMatrix([3, 1, 2], [0.1, 0.2, 0.3]) |> staticize)
    @test pm ≈ PermMatrix([1, 4, 2, 3], [1, 0.1, 0.2, 0.3])

    nbit = 4
    mmm = X |> mat
    m1 = unmat(Val(2), nbit, mmm, (2,))
    m2 = YaoArrayRegister.linop2dense(v -> instruct!(Val(2), v, mmm, (2,)), nbit)
    @test m1 ≈ m2
end

@testset "identity-unmat" begin
    nbit = 4
    mmm = Z |> mat
    m1 = unmat(Val(2), nbit, mmm, (2,))
    m2 = YaoArrayRegister.linop2dense(v -> instruct!(Val(2), v, mmm, (2,)), nbit)
    @test m1 ≈ m2

    nbit = 4
    mmm = igate(2) |> mat
    m1 = unmat(Val(2), nbit, mmm, (2,1))
    m2 = YaoArrayRegister.linop2dense(v -> instruct!(Val(2), v, mmm, (2,1)), nbit)
    @test m1 ≈ m2
end

@testset "fix-static and adjoint for mat" begin
    G1 = matblock(rand_unitary(2))
    G6 = matblock(rand_unitary(1 << 6))
    @test mat(put(3, 2 => G1')) ≈ mat(put(3, 2 => matblock(G1)))'
    @test mat(put(7, (3, 2, 1, 5, 4, 6) => G6')) ≈ mat(put(7, (3, 2, 1, 5, 4, 6) => G6))'
end

@testset "use routines" begin
    rows, vals = YaoBlocks.unsafe_getcol(ComplexF64, put(5, 1=>ConstGate.P1), bit"00000")
    @test eltype(rows) <: DitStr
    @test eltype(vals) <: ComplexF64
end
