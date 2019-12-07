using Test, YaoSym, YaoBase

@testset "constructors" begin
    @test ket"011" isa SymReg
    @test (ket"011")' isa AdjointSymReg
end

@testset "partial_tr" begin
    @vars α β
    r = α * ket"101" + β * ket"111"
    @test partial_tr(r, 2:3) == (α + β) * ket"1"
end
