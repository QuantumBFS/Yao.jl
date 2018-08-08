using Test, Random, LinearAlgebra, SparseArrays

using Yao
using Yao.Zoo
using FFTW

@testset "QFT" begin
    num_bit = 5
    fftblock = QFTCircuit(num_bit)
    ifftblock = adjoint(fftblock)
    reg = rand_state(num_bit)
    rv = copy(statevec(reg))

    @test Matrix(mat(chain(3, QFTCircuit(3) |> adjoint, QFTCircuit(3)))) ≈ eye(1<<3)

    # test ifft
    reg1 = copy(reg) |>ifftblock

    # permute lines (Manually)
    kv = fft(reg|>statevec)/sqrt(length(rv))
    @test reg1|>statevec ≈ kv |> invorder

    # test fft
    reg2 = copy(reg) |> invorder! |> fftblock
    kv = ifft(rv)*sqrt(length(rv))
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

    @test Matrix(mat(chain(3, QFTBlock{3}() |> adjoint, QFTBlock{3}()))) ≈ eye(1<<3)

    # permute lines (Manually)
    @test copy(reg) |>iqft ≈ copy(reg) |> (QFTBlock{num_bit}()|>adjoint)

    # test fft
    @test copy(reg) |> qft ≈ copy(reg) |> qftblock
end
