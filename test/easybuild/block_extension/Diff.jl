using Yao.EasyBuild
using YaoBlocks.ConstGate
using LinearAlgebra, Test, Random
using YaoBlocks.AD: Rotor, generator

@testset "Diff Block" begin
    reg = rand_state(4)
    block = put(4, 2=>rot(X, 0.3))
    df = Diff(block)
    @test nqubits(df) == 4

    df2 = Diff(rot(CNOT, 0.3))
    @test nqubits(df2) == 2

    reg = rand_state(4)
    df2 = Diff(rot(CNOT, 0.3))
    @test nqubits(df2) == 2

    @test df2' isa Diff
    @test mat(df2) == mat(df2')'

    circuit = chain(put(4, 1=>Rx(0.1)), control(4, 2, 1=>Ry(0.3)))
    c2 = circuit |> markdiff
    @test c2[1].content isa Diff
    @test !(c2[2] isa Diff)
end
