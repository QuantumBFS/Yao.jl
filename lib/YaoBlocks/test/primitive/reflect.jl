using YaoBlocks, YaoArrayRegister
using Test, LinearAlgebra

@testset "test reflect gate" begin
    reg0 = rand_state(3)
    mirror = randn(1<<3)*im; mirror[:] /= norm(mirror)
    rf = reflect(ArrayReg(mirror))
    reg = copy(reg0)
    apply!(reg, rf)

    v0, v1 = vec(reg.state), vec(reg0.state)
    @test mat(rf) * statevec(reg0) ≈ statevec(apply!(copy(reg0), rf))
    @test statevec(rf.psi)' * v0 ≈ statevec(rf.psi)' * v1
    @test v0 - statevec(rf.psi)'*v0* statevec(rf.psi) ≈
        -(v1- statevec(rf.psi)' * v1 * statevec(rf.psi))

    @test mat(ComplexF32, rf) == ComplexF32.(mat(rf))

    @test rf == reflect(rf.psi)
    # copy do not occur on register
    @test copy(rf) == rf

    @test ishermitian(rf)
    @test isreflexive(rf)
    @test isunitary(rf)
    @test isunitary(rf) == isunitary(mat(rf))
    @test ishermitian(mat(rf)) == ishermitian(rf)
    @test isreflexive(mat(rf)) == isreflexive(rf)
end
