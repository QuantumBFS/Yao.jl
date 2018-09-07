using Test, Random, LinearAlgebra, SparseArrays

using Yao
using LuxurySparse
using Yao.Blocks

@testset "constructor" begin
@test ShiftGate(0.1) isa ShiftGate{Float64}
@test_throws TypeError ShiftGate{ComplexF32} # will not accept non-real type
end

@testset "matrix" begin
g = ShiftGate{Float64}(pi)
@test mat(g) ≈ exp(im * pi/2) * [exp(-im * pi/2) 0; 0  exp(im * pi/2)]
end

@testset "apply" begin
g = ShiftGate{Float64}(pi)
reg = rand_state(1)
@test mat(g) * state(reg) ≈ state(apply!(reg, g))
end

@testset "compare" begin
@test (ShiftGate(2.0) == ShiftGate(2.0)) == true
@test (ShiftGate(2.0) == ShiftGate(1.0)) == false
end

@testset "copy" begin
g = ShiftGate(0.1)
cg = copy(g)
cg.theta = 0.2
@test g.theta == 0.1
end

@testset "traits" begin
g = ShiftGate{Float64}(0.1)
@test nqubits(g) == 1
@test ninput(g) == 1
@test noutput(g) == 1
@test isreflexive(g) == false
@test isunitary(g) == true
@test ishermitian(g) == false
end

@testset "hash" begin
g = ShiftGate{Float64}(pi)
for i = 1:1000
    hash1 = hash(g)
    g.theta = rand()
    hash2 = hash(g)
    @test hash1 != hash2
    @test hash2 == hash(g)
end
end
