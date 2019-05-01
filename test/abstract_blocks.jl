using Test, YaoBlocks

@testset "Yao/#186" begin
    @test getiparams(phase(0.1)) == 0.1
    @test getiparams(2 * phase(0.1)) == ()
end
