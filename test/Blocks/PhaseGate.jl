using Compat.Test
using Compat
using QuCircuit
import QuCircuit: PhaseGate, PrimitiveBlock

@testset "constructor" begin
@test isa(PhaseGate{:global, Float64}(0.1), PrimitiveBlock{1, ComplexF64})
@test isa(PhaseGate{:global, Float32}(0.1f0), PrimitiveBlock{1, ComplexF32})
@test_throws TypeError PhaseGate{:global, ComplexF32} # will not accept non-real type
end

@testset "matrix" begin
g = PhaseGate{:shift, Float64}(pi)
@test full(g) ≈ exp(im * pi/2) * [exp(-im * pi/2) 0; 0  exp(im * pi/2)]
g = PhaseGate{:global, Float64}(pi)
@test full(g) ≈ exp(im * pi) * eye(2)
end

@testset "apply" begin
g = PhaseGate{:shift, Float64}(pi)
reg = rand_state(1)
@test full(g) * state(reg) ≈ state(apply!(reg, g))
@test full(g) * state(reg) ≈ state(g(reg))
end

@testset "compare" begin
@test (PhaseGate{:shift, Float64}(2.0) == PhaseGate{:shift, Float64}(2.0)) == true
@test (PhaseGate{:shift, Float64}(2.0) == PhaseGate{:shift, Float64}(1.0)) == false
@test (PhaseGate{:global, Float64}(2.0) != PhaseGate{:shift, Float64}(2.0)) == true
end

@testset "copy" begin
g = PhaseGate{:shift, Float64}(0.1)
cg = copy(g)
cg.theta = 0.2
@test g.theta == 0.1
end

@testset "traits" begin
g = PhaseGate{:shift, Float64}(0.1)
@test nqubits(g) == 1
@test ninput(g) == 1
@test noutput(g) == 1
@test isreflexive(g) == false
@test isunitary(g) == true
@test ispure(g) == true
@test ishermitian(g) == false
end

@testset "hash" begin
g = PhaseGate{:shift, Float64}(pi)
for i = 1:1000
    hash1 = hash(g)
    g.theta = rand()
    hash2 = hash(g)
    @test hash1 != hash2
    @test hash2 == hash(g)
end
end
