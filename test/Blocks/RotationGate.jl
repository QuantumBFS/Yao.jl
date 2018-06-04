using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao
using Yao.Blocks

@testset "constructor" begin
@test isa(RotationGate(X, 0.1), PrimitiveBlock{1, ComplexF64})
@test isa(RotationGate(X(ComplexF32), 0.1f0), PrimitiveBlock{1, ComplexF32})
@test isa(RotationGate(X, 0.1), RotationGate{Float64, XGate{ComplexF64}})
@test_throws TypeError RotationGate{ComplexF32, XGate{ComplexF64}} # will not accept non-real type
end

@testset "matrix" begin
theta = 2.0
for (DIRECTION, MAT) in [
    (X, [cos(theta/2) -im*sin(theta/2); -im*sin(theta/2) cos(theta/2)]),
    (Y, [cos(theta/2) -sin(theta/2); sin(theta/2) cos(theta/2)]),
    (Z, [exp(-im*theta/2) 0;0 exp(im*theta/2)])
]
    @test mat(RotationGate(DIRECTION, theta)) ≈ MAT
end

end

@testset "copy & dispatch" begin
g = RotationGate(X, 0.1)
cg = copy(g)
@test cg == g
@test cg !== g # shallow copy (not recursive)
cg.theta = 1.0
@test g.theta == 0.1
@test dispatch!(g, 1.0).theta == 1.0
end

@testset "apply" begin
g = RotationGate(X, 0.1)
reg = rand_state(1)
@test mat(g) * state(reg) == state(apply!(reg, g))
@test mat(g) * state(reg) == state(g(reg))
end

@testset "hash & compare" begin
# test collision
@testset "test collision" begin
    g = RotationGate(X, 0.1)
    for i=1:1000
        hash1 = hash(g)
        g.theta = rand()
        hash2 = hash(g)
        @test hash1 != hash2
    end
end
# compare method

directions = [X, Y, Z]
for (lhs, rhs) in zip(directions, directions)
    @test (RotationGate(lhs, 2.0) == RotationGate(rhs, 2.0)) == (lhs == rhs)
end
end
