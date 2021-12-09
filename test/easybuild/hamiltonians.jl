using Yao
using Test
using Yao.ConstGate

@testset "solving hamiltonian" begin
    nbit = 8
    h = heisenberg(nbit) |> cache
    @test ishermitian(h)
    h = transverse_ising(nbit)
    @test ishermitian(h)
end
