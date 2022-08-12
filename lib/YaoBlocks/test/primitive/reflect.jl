using YaoBlocks, YaoArrayRegister
using Test, LinearAlgebra

@testset "test reflect gate" begin
    for reg in [rand_state(3), arrayreg(rand_unitary(8)[:,1:3]; nbatch=3)]
        rf = reflect(reg)
        reg0 = rand_state(3)
        reg = copy(reg0)
        apply!(reg, rf)

        v0, v1 = reg.state, reg0.state
        @test mat(rf) * state(reg0) ≈ state(apply!(copy(reg0), rf))
        @test state(rf.H.psi)' * v0 ≈ -state(rf.H.psi)' * v1
        @test isapprox(v0 - state(rf.H.psi) * (state(rf.H.psi)'*v0),
            (v1- state(rf.H.psi) * (state(rf.H.psi)' * v1)); atol=1e-8)

        @test mat(ComplexF32, rf) ≈ ComplexF32.(mat(rf))

        @test rf == reflect(rf.H.psi)
        # copy do not occur on register
        @test copy(rf) == rf

        @test isunitary(rf) == isunitary(mat(rf))
        @test (mat(rf) ≈ mat(rf)') == ishermitian(rf)
        @test isreflexive(mat(rf)) == isreflexive(rf)
    end

    rf = reflect(arrayreg(rand_unitary(8)[:,1:3]; nbatch=3), π/8)
    reg0 = rand_state(3)
    reg = copy(reg0)
    apply!(reg, rf)

    v0, v1 = reg.state, reg0.state
    @test mat(rf) * state(reg0) ≈ state(apply!(copy(reg0), rf))
    @test invoke(mat, Tuple{TimeEvolution}, rf) ≈ mat(rf)
    @test state(rf.H.psi)' * v0 ≈ exp(-im*π/8)*state(rf.H.psi)' * v1
    @test isapprox(v0 - state(rf.H.psi) * (state(rf.H.psi)'*v0),
        (v1- state(rf.H.psi) * (state(rf.H.psi)' * v1)); atol=1e-8)

    @test mat(ComplexF32, rf) ≈ ComplexF32.(mat(rf))

    @test rf == reflect(rf.H.psi, π/8)
    # copy do not occur on register
    @test copy(rf) == rf

    @test isunitary(rf) == isunitary(mat(rf))
    @test (mat(rf) ≈ mat(rf)') == ishermitian(rf)
    @test isreflexive(mat(rf)) == isreflexive(rf)
end