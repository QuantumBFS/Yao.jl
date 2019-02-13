using YaoBase
using Test

# mocked registers
struct TestRegister{B, T} <: AbstractRegister{B, T}
end

TestRegister() = TestRegister{1, Float64}()

YaoBase.nqubits(::TestRegister) = 8
YaoBase.nactive(::TestRegister) = 2

export TestInterfaceRegister
struct TestInterfaceRegister{B, T} <: AbstractRegister{B, T}
end

TestInterfaceRegister() = TestInterfaceRegister{1, Float64}()

@testset "Test general interface" begin
    @test_throws NotImplementedError nactive(TestInterfaceRegister())
    @test_throws NotImplementedError nqubits(TestInterfaceRegister())
    @test_throws NotImplementedError nremain(TestInterfaceRegister())
end

@testset "Test default fallbacks" begin
    @test nbatch(TestInterfaceRegister()) == 1
end

@testset "Test Printing" begin
    @test repr(TestRegister()) == """
    TestRegister{1,Float64}
        active qubits: 2/8"""
end

@testset "Test adjoint printing" begin
    @test repr(adjoint(TestRegister())) == """
        adjoint(TestRegister{1,Float64})
            active qubits: 2/8"""
end
