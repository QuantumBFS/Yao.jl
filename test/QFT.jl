using Test, Random, LinearAlgebra, SparseArrays, LuxurySparse

using Yao
using YaoArrayRegister: invorder
using QuAlgorithmZoo
using FFTW

@testset "QFT" begin
    num_bit = 5
    fftblock = QFTCircuit(num_bit)
    ifftblock = fftblock'
    reg = rand_state(num_bit)
    rv = copy(statevec(reg))

    @test Matrix(mat(chain(3, QFTCircuit(3) |> adjoint, QFTCircuit(3)))) ≈ IMatrix(1<<3)

    # test ifft
    reg1 = apply!(copy(reg), ifftblock)

    # permute lines (Manually)
    kv = fft(statevec(reg))/sqrt(length(rv))
    @test statevec(reg1) ≈ invorder(kv)

    # test fft
    reg2 = apply!(invorder!(copy(reg)), fftblock)
    kv = ifft(rv) * sqrt(length(rv))
    @test statevec(reg2) ≈ kv
end


@testset "QFTBlock" begin
    num_bit = 5
    qft = QFTCircuit(num_bit)
    iqft = adjoint(qft)
    qftblock = QFTBlock{num_bit}()
    iqftblock = QFTBlock{num_bit}() |> adjoint
    @test openbox(qftblock) == qft
    @test openbox(iqftblock) == iqft
    reg = rand_state(num_bit)

    @test Matrix(mat(chain(3, QFTBlock{3}() |> adjoint, QFTBlock{3}()))) ≈ IMatrix(1<<3)

    # permute lines (Manually)
    @test apply!(copy(reg), iqft) ≈ apply!(copy(reg), QFTBlock{num_bit}() |> adjoint)

    # test fft
    @test apply!(copy(reg), qft) ≈ apply!(copy(reg), qftblock)

    # regression test for nactive
    @test apply!(focus!(copy(reg), 1:3), QFTBlock{3}()) |> isnormalized
end
