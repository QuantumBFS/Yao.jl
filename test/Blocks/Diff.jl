using Yao
using Yao.Blocks
using LinearAlgebra, Test

@testset "BP diff" begin
    reg = rand_state(4)
    block = put(4, 2=>rot(X, 0.3))
    df = BPDiff(block)
    @test df.grad == 0
    @test nqubits(df) == 4

    df2 = BPDiff(rot(CNOT, 0.3))
    @test df2.grad == 0
    @test nqubits(df2) == 2
end

@testset "Qi diff" begin
    reg = rand_state(4)
    df2 = QDiff(rot(CNOT, 0.3))
    @test df2.grad == 0
    @test nqubits(df2) == 2

    @test df2' isa QDiff
    @test mat(df2) == mat(df2')'
end
