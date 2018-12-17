using YaoBase
using YaoBase.TestUtils
using Test

@testset "Test general interface" begin
    @test_throws NotImplementedError nactive(TestInterfaceRegister())
    @test_throws NotImplementedError nqubits(TestInterfaceRegister())
    @test_throws NotImplementedError nremain(TestInterfaceRegister())
end

@testset "Test default fallbacks" begin
    @test nbatch(TestInterfaceRegister()) == 1
end

@testset "Test Printing" begin
    @test_io TestRegister() """
    TestRegister{1,Float64}
        active qubits: 2/8
    """
end
