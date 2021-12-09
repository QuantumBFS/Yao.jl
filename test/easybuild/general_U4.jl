using Yao, Test
@testset "general U2 U4" begin
    c = general_U2(0.5, 0.7, 0.9; ϕ=0.8)
    @test length(c) == 4
    c = general_U2(0.5, 0.7, 0.9)
    @test length(c) == 3

    params = rand(17)*2π
    @test_throws ArgumentError general_U4(params)
    params = rand(15)*2π
    g = general_U4(params)
    gc = gatecount(g)
    @test gc[typeof(Ry(0.0))] == 6
    @test gc[typeof(Rz(0.0))] == 9
    @test gc[typeof(cnot(2,2,1))] == 3
    @test parameters(g) ≈ params
end
