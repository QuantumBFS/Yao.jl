using Test, YaoBase, YaoBase.TestUtils

@testset "test exception msg" begin
    @test repr(NotImplementedError(:nqubits)) == "nqubits is not implemented."
end
