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
    @test isdiagonal(block) == isdiagonal(mat(block)) == true
    @test occupied_locs(block) == ()
    @test getiparams(block) == ()
    @test nqudits(igate(3; nlevel=3)) == 3
    @test mat(igate(3; nlevel=3)) == YaoBlocks.IMatrix{27}()
end


@testset "instruct_get_element" begin
    for pb in [igate(1), igate(2; nlevel=3)
            ]
        mpb = mat(pb)
        allpass = true
        for i=basis(pb), j=basis(pb)
            allpass &= pb[i, j] == mpb[Int(i)+1, Int(j)+1]
        end
        @test allpass

        allpass = true
        for j=basis(pb)
            allpass &= vec(pb[:, j]) == mpb[:, Int(j)+1]
            allpass &= vec(pb[j,:]) == mpb[Int(j)+1,:]
            allpass &= isclean(pb[:,j])
        end
        @test allpass
    end
end