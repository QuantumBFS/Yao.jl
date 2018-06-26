using Yao
using Yao.Zoo
using Yao.Blocks
using Compat
using Compat.Test

@testset "rotter, collect_rotblocks, num_gradient, opgrad" begin
    c = diff_circuit(4, 3, [1=>3, 2=>4, 2=>3, 4=>1])
    rots = collect_rotblocks(c)
    @test length(rots) == nparameters(c) == 40

    obs = kron(nqubits(c), 2=>X)
    @test mean(opgrad(obs, zero_state(4)=>c, rots) .|> abs) > 3e-3
    @test isapprox(opgrad(obs, zero_state(4)=>c, rots),  num_gradient(r->expect(obs, r), zero_state(4)=>c, rots), atol=1e-3)

    @test  rotter(true, true) == Rx(0)
    @test  rotter(false, false) == rotter() == chain(Rz(0), Rx(0), Rz(0))
    @test  rotter(false, true) == chain(Rz(0), Rx(0))
    @test  rotter(true, false) == chain(Rx(0), Rz(0))
end
