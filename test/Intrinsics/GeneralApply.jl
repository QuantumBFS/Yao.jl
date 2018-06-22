using Compat
using Compat.Test
using StaticArrays: SVector, SMatrix
using Yao.Intrinsics: u1rows!, unrows!, u1apply!, unapply!

⊗ = kron
u1 = randn(ComplexF64, 2, 2)
v = randn(ComplexF64, 1<<4)
II = eye(2)

@testset "apply!" begin
    @test u1apply!(copy(v), u1, 3) ≈ (II ⊗ u1 ⊗ II ⊗ II)*v ≈ u1apply!(reshape(copy(v), :,1), u1, 3)
    @test unapply!(copy(v), u1, [3]) == u1apply!(copy(v), u1, 3)
    @test unapply!(copy(v), kron(u1, u1), [3, 1]) ≈ u1apply!(u1apply!(copy(v), u1, 3), u1, 1)
    @test unapply!(reshape(copy(v), :,1), kron(u1, u1), [3, 1]) ≈ u1apply!(u1apply!(reshape(copy(v),:,1), u1, 3), u1, 1)
end
