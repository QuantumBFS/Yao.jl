using Test, YaoBase

@testset "test exception msg" begin
    @test repr(NotImplementedError(:nqubits)) == "nqubits is not implemented."
end
