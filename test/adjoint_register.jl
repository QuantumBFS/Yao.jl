using YaoBase, YaoBase.TestUtils, Test

@testset "Test adjoint printing" begin
    @test_io adjoint(TestRegister()) """
        adjoint(TestRegister{1,Float64})
            active qubits: 2/8"""
end
