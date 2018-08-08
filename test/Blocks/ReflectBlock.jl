using Test, Random, LinearAlgebra, SparseArrays

using Yao
using Yao.Blocks

import Yao.Blocks: ReflectBlock

@testset "ReflectBlock" begin
    reg0 = rand_state(3)
    mirror = randn(1<<3)*im; mirror[:]/=norm(mirror)
    rf = ReflectBlock(mirror)
    reg = copy(reg0)
    apply!(reg, rf)

    v0, v1 = vec(reg.state), vec(reg0.state)
    @test mat(rf)*(reg0|>statevec) ≈ apply!(copy(reg0), rf) |> statevec
    @test (rf.psi |> statevec)'*v0 ≈ (rf.psi |> statevec)'*v1
    @test v0-(rf.psi |> statevec)'*v0*(rf.psi |> statevec) ≈ -(v1-(rf.psi |> statevec)'*v1*(rf.psi |> statevec))
end
