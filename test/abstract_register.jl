using YaoBase
using YaoBase.TestUtils
using Test

struct TestRegister{B, T} <: AbstractRegister{B, T}
end

TestRegister() = TestRegister{1, Float64}()

@testset "YaoBase.jl" begin
    @test_throws NotImplementedError nactive(TestRegister())
    @test_throws NotImplementedError nqubits(TestRegister())
    @test_throws NotImplementedError nremain(TestRegister())
end

@testset "Test Printing" begin
    YaoBase.nactive(r::TestRegister) = 2
    YaoBase.nqubits(r::TestRegister) = 3

    @test_io TestRegister() """
    TestRegister{1,Float64}
        active qubits: 2/3
    """
end
