using YaoBlocks, YaoArrayRegister
using Test, LinearAlgebra

@testset "test projector" begin
    reg0 = rand_state(3)
    rf = projector(reg0)
    @test mat(rf) ≈ state(reg0) * state(reg0)'
    reg = copy(reg0)
    apply!(reg, rf)

    v0, v1 = vec(reg.state), vec(reg0.state)
    @test mat(rf) * statevec(reg0) ≈ statevec(apply!(copy(reg0), rf))
    @test mat(rf) ≈ mat(rf^2)
    @test statevec(rf.psi)' * v0 ≈ statevec(rf.psi)' * v1
    @test statevec(rf.psi)'*v0* statevec(rf.psi) ≈ v1

    @test mat(ComplexF32, rf) ≈ ComplexF32.(mat(rf))

    @test rf == projector(rf.psi)
    # copy do not occur on register
    @test copy(rf) == rf

    @test ishermitian(rf)
    @test !isreflexive(rf)
    @test !isunitary(rf)
    @test isunitary(rf) == isunitary(mat(rf))
    @test ishermitian(mat(rf)) == ishermitian(rf)
    @test isreflexive(mat(rf)) == isreflexive(rf)
end
