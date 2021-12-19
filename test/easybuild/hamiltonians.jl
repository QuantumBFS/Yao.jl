using Yao.EasyBuild
using Test
using Yao.ConstGate

@testset "solving hamiltonian" begin
    nbit = 8
    h = heisenberg(nbit) |> cache
    @test ishermitian(h)
    h = transverse_ising(nbit, 1.0)
    @test ishermitian(h)
end
