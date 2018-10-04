using Test, Random, LinearAlgebra, SparseArrays


using Yao, QuAlgorithmZoo, Yao.Blocks

@testset "rotter, collect_rotblocks, num_gradient, opgrad" begin
    c = diff_circuit(4, 3, [1=>3, 2=>4, 2=>3, 4=>1])
    rots = collect_rotblocks(c)
    @test length(rots) == nparameters(c) == 40

    obs = kron(nqubits(c), 2=>X)
    #@test mean(opgrad(()->expect(obs, apply!(zero_state(4), c))|>real, rots) .|> abs) > 3e-4
    gradA = opgrad(()->expect(obs, apply!(zero_state(4), c)) |> real, rots)
    gradB = num_gradient(()->expect(obs, apply!(zero_state(4),c)) |> real, rots)
    @test isapprox(gradA, gradB, atol=1e-4)

    @test  rotter(true, true) == Rx(0)
    @test  rotter(false, false) == rotter() == chain(Rz(0), Rx(0), Rz(0))
    @test  rotter(false, true) == chain(Rz(0), Rx(0))
    @test  rotter(true, false) == chain(Rx(0), Rz(0))
end
