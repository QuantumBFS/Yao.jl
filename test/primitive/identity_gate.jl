using YaoBlocks, YaoArrayRegister
using Random, Test

@testset "identity gate" begin
    block = igate(4)
    reg = rand_state(4)
    @test reg |> block == reg
    @test mat(block) != nothing
    @test ishermitian(block)
    @test isreflexive(block)
    @test isunitary(block)
    @test getiparams(block) == ()
end
