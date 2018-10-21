using Test, LinearAlgebra
using Yao, Yao.Blocks
using Yao.Blocks: cache_key

@testset "Adder" begin
    ad = Adder(put(3, 2=>X), 3*put(3, 1=>rot(Y, 0.3)), repeat(3, Z, (2,3)))
    @test ad |> usedbits |> sort! == [1,2,3]
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
    ad3 = chsubblocks(ad, [put(3, 1=>X)])
    append!(prepend!(ad3, [rot(Toffoli, 0.2)]), [control(3, 1, 2=>X)])
    @test ad3 == Adder(rot(Toffoli, 0.2), put(3, 1=>X), control(3, 1, 2=>X))
    ad3[3] = ad3[1]
    @test ad3 == Adder(rot(Toffoli, 0.2), put(3, 1=>X), rot(Toffoli, 0.2))
    @test ad3' == Adder(rot(Toffoli, -0.2), put(3, 1=>X), rot(Toffoli, -0.2))

    ad4 = similar(ad3)
    @test typeof(ad4) == typeof(ad3)
    @test length(ad4) == 0

    reg = rand_state(3)
    @test apply!(copy(reg), ad) ≈ apply!(copy(reg), ad[1]) + apply!(copy(reg), ad[2]) + apply!(copy(reg), ad[3])
    @test mat(ad)*reg.state ≈ apply!(copy(reg), ad[1]) + apply!(copy(reg), ad[2]) + apply!(copy(reg), ad[3]) |> state
end

@testset "add arithmatics" begin
    g1 = put(3, 1=>X)
    g2 = put(3, 2=>Y)
    g3 = put(3, 3=>Z)
    @test g1 + g2 == Adder(g1, g2)
    @test g1 + g2 + g3 == Adder(g1, g2, g3)
    B0 = (g1 + g2 + g3)
    B1 = 3*B0
    @test B1 isa Adder
    @test mat(B1) == 3*mat(B0)
    @test g1*(g3+g2) isa Adder
    @test g1*(g3+g2) |> mat == mat(g1)*(mat(g2)+mat(g3))
    @test g1*g2 isa ChainBlock
    @test mat(g1*g2) ≈ mat(g1)*mat(g2)
    @test mat(g1*g2*g3) ≈ mat(g1)*mat(g2)*mat(g3)
    @test mat(g1*(g2*g3)) ≈ mat(g1)*mat(g2)*mat(g3)
    @test mat(2g1*(g2*g3)) ≈ 2*mat(g1)*mat(g2)*mat(g3)
    @test mat(g1*(2*(g2*g3))) ≈ 2*mat(g1)*mat(g2)*mat(g3)
    @test g1*g2 isa ChainBlock
    @test (g1*g2)*(g3+g2) |> mat |> Matrix ≈ Matrix(mat(g1)*mat(g2)*(mat(g2)+mat(g3)))
    @test (g1+g3)*(g3+g2) |> mat ≈ (mat(g1)+mat(g3))*(mat(g2)+mat(g3))
end
