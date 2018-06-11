using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao
using Yao.LuxurySparse
using Yao.Blocks

@testset "constructor" begin
@test isa(PhaseGate{Float64}(0.1), PrimitiveBlock{1, ComplexF64})
@test isa(PhaseGate{Float32}(0.1f0), PrimitiveBlock{1, ComplexF32})
@test_throws TypeError PhaseGate{ComplexF32} # will not accept non-real type
end

@testset "matrix" begin
g = PhaseGate{Float64}(pi)
@test mat(g) ≈ exp(im * pi) * IMatrix(2)
end

@testset "apply" begin
g = PhaseGate{Float64}(pi)
reg = rand_state(1)
@test mat(g) * state(reg) ≈ state(apply!(reg, g))
end

@testset "compare" begin
@test (PhaseGate(2.0) == PhaseGate(2.0)) == true
end

@testset "copy" begin
g = PhaseGate(0.1)
cg = copy(g)
cg.theta = 0.2
@test g.theta == 0.1
end

@testset "traits" begin
g = PhaseGate{Float64}(0.1)
@test nqubits(g) == 1
@test isreflexive(g) == false
@test isunitary(g) == true
@test ishermitian(g) == false
end

@testset "hash" begin
g = PhaseGate{Float64}(pi)
for i = 1:1000
    hash1 = hash(g)
    g.theta = rand()
    hash2 = hash(g)
    @test hash1 != hash2
    @test hash2 == hash(g)
end
end
