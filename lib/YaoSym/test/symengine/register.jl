using Test, YaoSym, YaoArrayRegister
using SymEngine

@testset "constructors" begin
    @test ket"011" isa SymReg
    @test (ket"011")' isa AdjointSymReg
end

@testset "conversion" begin
    r = zero_state(3)
    sr = SymReg(r)

    for i in eachindex(r.state)
        @test r.state[i] ≈ N(sr.state[i])
    end
end
