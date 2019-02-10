using Test, Random, LinearAlgebra, SparseArrays

using YaoBase, YaoBlockTree

@testset "ReflectBlock" begin
    reg0 = rand_state(3)
    mirror = randn(1<<3)*im; mirror[:] /= norm(mirror)
    rf = ReflectBlock(mirror)
    reg = copy(reg0)
    apply!(reg, rf)

    v0, v1 = vec(reg.state), vec(reg0.state)
    @test mat(rf) * statevec(reg0) ≈ statevec(apply!(copy(reg0), rf))
    @test statevec(rf.psi)' * v0 ≈ statevec(rf.psi)' * v1
    @test v0 - statevec(rf.psi)'*v0* statevec(rf.psi) ≈ -(v1- statevec(rf.psi)' * v1 * statevec(rf.psi))
end
