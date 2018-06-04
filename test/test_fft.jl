using Compat.Test
include("fft.jl")

num_bit = 5
ifftblock = QIFFT(num_bit)
fftblock = QFFT(num_bit)
reg = rand_state(num_bit)
rv = copy(statevec(reg))

rotgate(gate::AbstractMatrix, θ::Real) = expm(-0.5im*θ*Matrix(gate))
apply2mat(applyfunc!::Function, num_bit::Int) = applyfunc!(eye(Complex128, 1<<num_bit))

@testset "fft" begin
    @test Matrix(mat(chain(QIFFT(3), QFFT(3)))) ≈ eye(1<<3)

    # test ifft
    reg1 = ifftblock(copy(reg))
    # permute lines (Manually)
    qkv = vec(permutedims(reshape(statevec(reg1), fill(2, num_bit)...), collect(num_bit:-1:1)))
    kv = ifft(rv)*sqrt(length(rv))
    @test qkv ≈ kv

    # test fft
    reg.state[:] = vec(permutedims(reshape(statevec(reg), fill(2, num_bit)...), collect(num_bit:-1:1)))
    reg2 = fftblock(copy(reg))
    kv = fft(rv)/sqrt(length(rv))
    @test statevec(reg2) ≈ kv
end
