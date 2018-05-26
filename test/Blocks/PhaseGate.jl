using Compat.Test
using Compat
using QuCircuit
import QuCircuit: PhiGate, PrimitiveBlock

@testset "constructor" begin
@test isa(PhiGate(0.1), PrimitiveBlock{1, ComplexF64})
@test isa(PhiGate(0.1f0), PrimitiveBlock{1, ComplexF32})
@test_throws TypeError PhiGate{ComplexF32} # will not accept non-real type
end

@testset "matrix" begin
g = PhiGate{Float64}(pi)
@test full(g) == exp(im * pi) * [exp(-im * pi) 0; 0  exp(im * pi)]
end

@testset "apply" begin
g = PhiGate{Float64}(pi)
reg = rand_state(1)
@test full(g) * state(reg) ≈ state(apply!(reg, g))
@test full(g) * state(reg) ≈ state(g(reg))
end

@testset "compare" begin
@test (PhiGate(2.0) == PhiGate(2.0)) == true
@test (PhiGate(2.0) == PhiGate(1.0)) == false
end

@testset "copy" begin
g = PhiGate(0.1)
cg = copy(g)
cg.theta = 0.2
@test g.theta == 0.1
end

@testset "traits" begin
g = PhiGate(0.1)
@test nqubit(g) == 1
@test ninput(g) == 1
@test noutput(g) == 1
@test isreflexive(g) == false
@test isunitary(g) == true
@test ispure(g) == true
@test ishermitian(g) == false
end

@testset "hash" begin
g = PhiGate{Float64}(pi)
for i = 1:1000
    hash1 = hash(g)
    g.theta = rand()
    hash2 = hash(g)
    @test hash1 != hash2
    @test hash2 == hash(g)
end
end
