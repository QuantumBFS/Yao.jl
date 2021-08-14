using Test, YaoBlocks, YaoArrayRegister, LuxurySparse


@testset "test constructor" for T in [Float16, Float32, Float64]
    @test PhaseGate(0.1) isa PrimitiveBlock{1}
    @test phase(T(0.1)) isa PrimitiveBlock{1}
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
    @test dispatch(phase(0.1), 3) == phase(3) && eltype(getiparams(dispatch(phase(0.1), 3))) == Int

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


    g = PhaseGate{ComplexF64}(1.0 + 0im)
    @test @test_nowarn isunitary(g) == true

    g = PhaseGate{ComplexF64}(1.0 + 1im)
    @test @test_logs (
        :warn,
        "θ in phase(θ) is not real, got $(g.theta), fallback to matrix-based method",
    ) isunitary(g) == false
end
