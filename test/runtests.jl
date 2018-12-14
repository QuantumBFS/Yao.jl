using YaoBase
using Test

struct TestRegister{B, T} <: AbstractRegister{B, T}
end

TestRegister() = TestRegister{1, Float64}()

@testset "YaoBase.jl" begin
    @test_throws NotImplementedError nactive(TestRegister())
end
