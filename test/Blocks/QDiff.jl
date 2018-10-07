using Yao
using Yao.Blocks
using LinearAlgebra, Test

@testset "Constrcut" begin
    reg = rand_state(4)
    df2 = QDiff(rot(CNOT, 0.3))
    @test df2.grad == 0
    @test nqubits(df2) == 2

    @test df2' isa QDiff
    @test mat(df2) == mat(df2')'
end
