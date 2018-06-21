using Yao
using Yao.Zoo
using Compat.Test
@static if VERSION >= v"0.7-"
    using FFTW
end

@testset "QFT" begin
    num_bit = 5
    fftblock = QFT(num_bit)
    ifftblock = adjoint(fftblock)
    reg = rand_state(num_bit)
    rv = copy(statevec(reg))

    @test Matrix(mat(chain(3, QFT(3) |> adjoint, QFT(3)))) ≈ eye(1<<3)

    # test ifft
    reg1 = copy(reg) |>ifftblock

    # permute lines (Manually)
    kv = ifft(reg|>statevec)*sqrt(length(rv))
    @test reg1|>statevec ≈ kv |> invorder

    # test fft
    reg2 = copy(reg) |> invorder! |> fftblock
    kv = fft(rv)/sqrt(length(rv))
    @test statevec(reg2) ≈ kv
end
