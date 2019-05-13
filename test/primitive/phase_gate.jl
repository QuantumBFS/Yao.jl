using Test, YaoBlocks, YaoArrayRegister, LuxurySparse


@testset "test constructor" for T in [Float16, Float32, Float64]
    @test PhaseGate(0.1) isa PrimitiveBlock{1}
    @test_throws TypeError PhaseGate{Complex{T}} # will not accept non-real type
    @test phase(T(0.1)) isa PrimitiveBlock{1}
    @test phase(1) isa PhaseGate{Float64} # default we convert to float64
end

@testset "test copy" begin
    g = PhaseGate(0.1)
    cg = copy(g)
    cg.theta = 0.2
    @test g.theta == 0.1
end

@testset "test matrix" begin
    g = PhaseGate{Float64}(pi)
    @test mat(g) ≈ exp(im * pi) * IMatrix(2)
end

@testset "test operations" begin
    g = PhaseGate{Float64}(pi)
    reg = rand_state(1)
    @test mat(g) * state(reg) ≈ state(apply!(reg, g))

    @test (PhaseGate(2.0) == PhaseGate(2.0)) == true
end

@testset "test dispatch & parameters" begin
    @test nparameters(phase(0.1)) == 1
    @test adjoint(phase(0.1)) == phase(-0.1)
    @test dispatch!(phase(0.1), 0.3) == phase(0.3)

    @testset "test $op" for op in [+, -, *, /]
        @test dispatch!(op, phase(0.1), π) == phase(op(0.1, π))
    end

    @test_throws AssertionError dispatch!(phase(0.1), (0.2, 0.3))
end

@testset "properties" begin
    g = PhaseGate{Float64}(0.1)
    @test nqubits(g) == 1
    @test isreflexive(g) == false
    @test isunitary(g) == true
    @test ishermitian(g) == false
end
