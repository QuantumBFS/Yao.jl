using Test, Random, LinearAlgebra, SparseArrays

using Yao
using Yao.Blocks

@testset "constructor" begin
    @test isa(RotationGate(X, 0.1), PrimitiveBlock{1, ComplexF64})
    @test isa(RotationGate(XGate{ComplexF32}(), 0.1f0), PrimitiveBlock{1, ComplexF32})
    @test isa(RotationGate(X, 0.1), RotationGate{1, Float64, XGate{ComplexF64}})
    @test isa(RotationGate(control(2, (2,), 1=>X), 0.1), RotationGate{2, Float64})
    @test_throws TypeError RotationGate{1, Float32, XGate{ComplexF64}} # will not accept non-real type
    @test chsubblocks(RotationGate(X, 0.1), ()) |> subblocks == ()
    @test setiparameters!(RotationGate(X, 0.0), 0.5).theta == 0.5
    @test setiparameters!(RotationGate(X, 0.0), :random).theta != 0.0
    @test setiparameters!(RotationGate(X, 2.0), :zero).theta == 0.0
end

@testset "matrix" begin
theta = 2.0
for (DIRECTION, MAT) in [
    (X, [cos(theta/2) -im*sin(theta/2); -im*sin(theta/2) cos(theta/2)]),
    (Y, [cos(theta/2) -sin(theta/2); sin(theta/2) cos(theta/2)]),
    (Z, [exp(-im*theta/2) 0;0 exp(im*theta/2)]),
    (CNOT, exp(-mat(CNOT)/2*theta*im |> Matrix)),
    (control(2, (1,), 2=>X), exp(-mat(CNOT)/2*theta*im |> Matrix))
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
@test dispatch!(g, [1.0]).theta == 1.0
end

@testset "apply" begin
g = RotationGate(X, 0.1)
reg = rand_state(1)
@test mat(g) * state(reg) ≈ state(apply!(reg, g))

rb = rot(CNOT, 0.5)
@test applymatrix(rb) ≈ mat(rb)
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
