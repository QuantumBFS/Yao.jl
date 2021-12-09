using Yao.EasyBuild
using Test

@testset "condition, t1, t2" begin
    m = Measure(1)
    reg = ArrayReg(ComplexF64[0,1])
    c = condition(m, X, nothing)
    @show c
    @test_throws UndefRefError reg |> c
    copy(reg) |> m
    @test (measure(reg |> c; nshots=10) .== 0) |> all

    m = Measure(1; locs=(1,))
    reg = ArrayReg(ComplexF64[0,1])
    c = condition(m, X, nothing)

    copy(reg) |> m
    @test all(measure(reg |> c; nshots=10) .==0)
end
