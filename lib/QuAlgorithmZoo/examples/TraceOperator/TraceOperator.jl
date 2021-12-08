using Yao
using QuAlgorithmZoo
using YaoBlocks.ConstGate
using Test
using LinearAlgebra

@testset "hadamard test" begin
    n = 2
    U = chain(put(n, 2=>Rx(0.2)), put(n, 1=>Rz(1.2)), put(n, 1=>phase(0.4)))
    US = chain(2n, put(2n, (3,4)=>U),
            chain(2n, [swap(2n,i,i+n) for i=1:n]))
    reg = zero_state(2n)
    reg |> repeat(2n, H, 1:n) |> chain(2n, [cnot(2n,i,i+n) for i=1:n])
    @show real(tr(mat(U)))/(1<<n)
    @test hadamard_test(US, reg, 0.0) ≈ real(tr(mat(U)))/(1<<n)
    @test hadamard_test(US, reg, -π/2) ≈ imag(tr(mat(U)))/(1<<n)
end
