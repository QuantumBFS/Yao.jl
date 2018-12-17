using Test, YaoBase, YaoBase.TestUtils

@testset "test exception msg" begin
    @test_io NotImplementedError(:nqubits) """
    nqubits is not implemented.
    """
end
