using Test, YaoBlocks

@testset "KrausChannel" begin
    op1 = matblock(rand_unitary(2))
    op2 = matblock(rand_unitary(2))
    kraus_channel = KrausChannel([op1, op2])
    @test kraus_channel.n == 1
    @test kraus_channel.operators == [op1, op2]
end
