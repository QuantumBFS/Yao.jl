using Yao.EasyBuild
using Test

@testset "SqrtX" begin
    @test mat(SqrtX)^2 ≈ mat(X)
    @test mat(SqrtY)^2 ≈ mat(Y)
    @test cz_entangler(5, [1=>2, 4=>5]) == chain(control(5, 1, 2=>Z), control(5, 4, 5=>Z))
end

@testset "supremacy" begin
    c = rand_supremacy2d(4, 4, 8)
    @test length(c) == 8
    @test length(pair_supremacy(6,6)) == 8
    @test pair_supremacy(6,6)[1] == [7=>8, 19=>20, 31=>32, 3=>4, 15=>16, 27=>28, 11=>12, 23=>24, 35=>36]
end
