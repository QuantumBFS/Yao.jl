using YaoBlocks, Test

@testset "errortypes" begin
    @test PauliError(BitFlipError(0.1)) == PauliError(0.1, 0.0, 0.0)
    @test PauliError(PhaseFlipError(0.1)) == PauliError(0.0, 0.0, 0.1)
    @test PauliError(DepolarizingError(0.1)) == PauliError(0.1/3, 0.1/3, 0.1/3)
    @test KrausChannel(BitFlipError(0.1)) == KrausChannel([sqrt(1-0.1)*I2, sqrt(0.1)*X])
    @test KrausChannel(PhaseFlipError(0.1)) == KrausChannel([sqrt(1-0.1)*I2, sqrt(0.1)*Z])
    @test KrausChannel(DepolarizingError(0.1)) == KrausChannel([sqrt(1-0.1)*I2, sqrt(0.1/3)*X, sqrt(0.1/3)*Y, sqrt(0.1/3)*Z])
    @test KrausChannel(ResetError(0.1, 0.2)) == KrausChannel([sqrt(1-0.1-0.2)*I2, sqrt(0.1)*ConstGate.P0, sqrt(0.1)*ConstGate.Pu, sqrt(0.2)*ConstGate.P1, sqrt(0.2)*ConstGate.Pd])
end