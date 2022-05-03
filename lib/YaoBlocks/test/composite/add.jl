using Test, YaoBlocks, YaoArrayRegister
import YaoBlocks.ConstGate: Toffoli
using YaoAPI: QubitMismatchError
using LinearAlgebra: I

@testset "Add" begin
    ad = Add(put(3, 2 => X), 3 * put(3, 1 => rot(Y, 0.3)), repeat(3, Z, (2, 3)))
    @test [push!(copy(ad), put(3, 1 => X))...] |> length == 4
    @test insert!(copy(ad), 2, put(3, 1 => X)) isa Add
    @test append!(copy(ad), [put(3, 1 => X)]) |> length == 4
    @test prepend!(copy(ad), [put(3, 1 => X)]) |> length == 4

    @test [occupied_locs(ad)...] |> sort! == [1, 2, 3]
    @test occupied_locs(+(put(5, 2 => X), put(5, 3 => I2))) == (2,)
    ad2 = copy(ad)
    @test ad2 == ad
    push!(ad2, Toffoli)
    @test ad2 != ad
    @test ad2[1:end-1] == ad
    @test ad2[end] == Toffoli
    @test length(ad2) == 4
    println(ad2)
    @test cache_key(ad) != cache_key(ad2)
    @test hash(ad) != hash(ad2)
    ad3 = chsubblocks(ad, [put(3, 1 => X)])
    append!(prepend!(ad3, [rot(Toffoli, 0.2)]), [control(3, 1, 2 => X)])
    @test ad3 == Add(rot(Toffoli, 0.2), put(3, 1 => X), control(3, 1, 2 => X))
    ad3[3] = ad3[1]
    @test ad3 == Add(rot(Toffoli, 0.2), put(3, 1 => X), rot(Toffoli, 0.2))
    @test ad3' == Add(rot(Toffoli, -0.2), put(3, 1 => X), rot(Toffoli, -0.2))

    ad4 = similar(ad3)
    @test typeof(ad4) == typeof(ad3)
    @test length(ad4) == 0

    reg = rand_state(3)
    @test apply!(copy(reg), ad) ≈
          apply!(copy(reg), ad[1]) + apply!(copy(reg), ad[2]) + apply!(copy(reg), ad[3])
    @test mat(ad) * reg.state ≈
          apply!(copy(reg), ad[1]) + apply!(copy(reg), ad[2]) + apply!(copy(reg), ad[3]) |>
          state

    @test Add(3) isa Add
    @test Add(3, [put(3, 3 => X)]) isa Add
    @test_throws QubitMismatchError Add(3, [put(10, 2 => X)])
    @test_throws QubitMismatchError Add(put(10, 2 => X), put(4, 3 => X))
    @test_throws QubitMismatchError apply!(rand_state(2), Add(put(10, 2 => X)))
end

@testset "getindex2" begin
    pb = put(3, 3=>Y) + control(3, (2,), 1=>X)
    mpb = mat(pb)
    allpass = true
    for i=basis(pb), j=basis(pb)
        allpass &= pb[i, j] == mpb[Int(i)+1, Int(j)+1]
    end
    @test allpass
    pb = put(5, 2=>Y) + control(5, (2,), (4,3)=>matblock(rand_unitary(4)))
    mpb = mat(pb)
    allpass = true
    for i=basis(pb), j=basis(pb)
        allpass &= pb[i, j] == mpb[Int(i)+1, Int(j)+1]
    end
    @test allpass
end