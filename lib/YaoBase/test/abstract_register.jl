using YaoBase
using Test

# mocked registers
struct TestRegister <: AbstractRegister{2} end

YaoBase.nqudits(::TestRegister) = 8
YaoBase.nactive(::TestRegister) = 2

export TestInterfaceRegister
struct TestInterfaceRegister <: AbstractRegister{2} end

@testset "Test general interface" begin
    @test_throws MethodError nactive(TestInterfaceRegister())
    @test_throws MethodError nqubits(TestInterfaceRegister())
    @test_throws MethodError nremain(TestInterfaceRegister())
end

@testset "adjoint register" begin
    @test adjoint(TestRegister()) isa AdjointRegister
    @test adjoint(adjoint(TestRegister())) isa TestRegister
    @test nqubits(adjoint(TestRegister())) == 8
    @test nactive(adjoint(TestRegister())) == 2
end