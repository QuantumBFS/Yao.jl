using Test
using YaoBlocks.AD
using YaoBlocks
using YaoArrayRegister

@testset "NoParams" begin
    c = chain(put(3, 2 => Ry(0.2)), put(3, 1 => Rx(0.5)))
    np = chain(NoParams(put(3, 2 => Ry(0.2))), put(3, 1 => Rx(0.5)))
    @test gatecount(np) == gatecount(c)
    reg = rand_state(3)
    @test content(np[1]) == put(3, 2 => Ry(0.2))
    @test parameters(np) == [0.5]
    @test nparameters(np) == 1
    @test getiparams(np[1]) == ()
    @test niparams(np[1]) == 0
    @test mat(c) ≈ mat(np)
    @test apply!(copy(reg), c) ≈ apply!(copy(reg), np)
    @test np' == chain(put(3, 1 => Rx(-0.5)), NoParams(put(3, 2 => Ry(-0.2))))
    @test dispatch!(np, [0.3]) ==
          chain(NoParams(put(3, 2 => Ry(0.2))), put(3, 1 => Rx(0.3)))

    u = chain(1, NoParams(Ry(1.0)), Rx(1.0))
    u2 = dispatch(u, [2.0]) # returns the following error 
    @test u2 == chain(1, NoParams(Ry(1.0)), Rx(2.0))
    @test chsubblocks(u2[1], X) == NoParams(X)
end
