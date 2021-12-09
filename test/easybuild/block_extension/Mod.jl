using Yao.EasyBuild, Test

@testset "Mod" begin
    @test_throws AssertionError Mod{4}(4,10)
    @test_throws AssertionError Mod{2}(3,10)
    m = Mod{4}(3,10)
    @test mat(m) ≈ applymatrix(m)
    @test isunitary(m)
    @test isunitary(mat(m))
    @test m' == Mod{4}(7,10)
end

@testset "KMod" begin
    @test_throws AssertionError KMod{6, 2}(4,10)
    @test_throws AssertionError KMod{4, 2}(3,10)
    m = KMod{6, 2}(3,10)
    @test mat(m) ≈ applymatrix(m)
    @test isunitary(m)
    @test isunitary(mat(m))
    @test m' == KMod{6, 2}(7,10)
end
