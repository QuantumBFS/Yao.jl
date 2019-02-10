using Test, LinearAlgebra
using YaoBase, YaoBlockTree, YaoDenseRegister
using YaoBlockTree: cache_key

@testset "AddBlock" begin
    ad = AddBlock(put(3, 2=>X), 3*put(3, 1=>rot(Y, 0.3)), repeat(3, Z, (2,3)))
    @test ad |> usedbits |> sort! == [1,2,3]
    ad2 = copy(ad)
    @test ad2 == ad
    push!(ad2, Toffoli)
    @test ad2 != ad
    @test ad2[1:end-1] == ad
    @test ad2[end] == Toffoli
    @test length(ad2) == 4

    @test cache_key(ad) != cache_key(ad2)
    @test hash(ad) != hash(ad2)
    ad3 = chsubblocks(ad, [put(3, 1=>X)])
    append!(prepend!(ad3, [rot(Toffoli, 0.2)]), [control(3, 1, 2=>X)])
    @test ad3 == AddBlock(rot(Toffoli, 0.2), put(3, 1=>X), control(3, 1, 2=>X))
    ad3[3] = ad3[1]
    @test ad3 == AddBlock(rot(Toffoli, 0.2), put(3, 1=>X), rot(Toffoli, 0.2))
    @test ad3' == AddBlock(rot(Toffoli, -0.2), put(3, 1=>X), rot(Toffoli, -0.2))

    ad4 = similar(ad3)
    @test typeof(ad4) == typeof(ad3)
    @test length(ad4) == 0

    reg = rand_state(3)
    @test apply!(copy(reg), ad) ≈ apply!(copy(reg), ad[1]) + apply!(copy(reg), ad[2]) + apply!(copy(reg), ad[3])
    @test mat(ad)*reg.state ≈ apply!(copy(reg), ad[1]) + apply!(copy(reg), ad[2]) + apply!(copy(reg), ad[3]) |> state
end
