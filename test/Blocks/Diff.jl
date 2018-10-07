using Yao
using Yao.Blocks
using LinearAlgebra, Test

@testset "Constrcut" begin
    reg = rand_state(4)
    block = put(4, 2=>rot(X, 0.3))
    df = Diff(block, copy(reg))
    @test df.grad == 0
    @test nqubits(df) == 4

    df2 = Diff(rot(CNOT, 0.3))
    @test df2.grad == 0
    @test nqubits(df2) == 2
end
