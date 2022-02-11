using YaoBase
using Test

# mocked registers
struct TestRegister{B} <: AbstractRegister{B,2} end

TestRegister() = TestRegister{1}()

YaoBase.nqudits(::TestRegister) = 8
YaoBase.nactive(::TestRegister) = 2

export TestInterfaceRegister
struct TestInterfaceRegister{B} <: AbstractRegister{B,2} end

TestInterfaceRegister() = TestInterfaceRegister{1}()

@testset "Test general interface" begin
    @test_throws MethodError nactive(TestInterfaceRegister())
    @test_throws MethodError nqubits(TestInterfaceRegister())
    @test_throws MethodError nremain(TestInterfaceRegister())
end

@testset "Test default fallbacks" begin
    @test nbatch(TestInterfaceRegister()) == 1
end

@testset "adjoint register" begin
    @test adjoint(TestRegister()) isa AdjointRegister
    @test adjoint(adjoint(TestRegister())) isa TestRegister
    @test nqubits(adjoint(TestRegister())) == 8
    @test nactive(adjoint(TestRegister())) == 2
end

@testset "Test Printing" begin
    @test repr(TestRegister()) == """
    TestRegister{1}
        active qudits: 2/8"""
end

@testset "Test adjoint printing" begin
    @test repr(adjoint(TestRegister())) == """
        adjoint(TestRegister{1})
            active qudits: 2/8"""
end
