using Test, YaoSym

@testset "constructors" begin
    @test ket"011" isa SymReg
    @test (ket"011")' isa AdjointSymReg
end
