using Test, YaoBlocks, YaoArrayRegister

@testset "test constructor" for T in [Float16, Float32, Float64]
    # NOTE: type should follow the axis
    @test RotationGate(X, 0.1) isa PrimitiveBlock{1}

    @test Rx(1) isa RotationGate{1,Float64,XGate}
    @test Rx(T(0.1)) isa RotationGate{1,T,XGate}
    @test Ry(T(0.1)) isa RotationGate{1,T,YGate}
    @test Rz(T(0.1)) isa RotationGate{1,T,ZGate}
end

@testset "test matrix" begin
    theta = 2.0
    for (DIRECTION, MAT) in [
        (X, [cos(theta / 2) -im * sin(theta / 2); -im * sin(theta / 2) cos(theta / 2)]),
        (Y, [cos(theta / 2) -sin(theta / 2); sin(theta / 2) cos(theta / 2)]),
        (Z, [exp(-im * theta / 2) 0; 0 exp(im * theta / 2)]),
        (CNOT, exp(-mat(CNOT) / 2 * theta * im |> Matrix)),
        (control(2, (1,), 2 => X), exp(-mat(CNOT) / 2 * theta * im |> Matrix)),
    ]
        @test mat(RotationGate(DIRECTION, theta)) ≈ MAT
    end
end

@testset "test apply" begin
    r = rand_state(1)
    @test state(apply!(copy(r), Rx(0.1))) ≈ mat(Rx(0.1)) * state(r)
end

@testset "test dispatch" begin
    @test dispatch!(Rx(0.1), 0.3) == Rx(0.3)
    @test nparameters(Rx(0.1)) == 1

    @testset "test $op" for op in [+, -, *, /]
        @test dispatch!(op, Rx(0.1), π) == Rx(op(0.1, π))
    end

    @test_throws AssertionError dispatch!(Rx(0.1), (0.2, 0.3))
end

@testset "adjoints" begin
    @test Rx(0.1)' == Rx(-0.1)
    @test Rx(0.2)' == Rx(-0.2)
    @test copy(Rx(0.1)) == Rx(0.1)

    g = Rx(0.1) # creates a new one
    @test copy(g) !== g
end

@testset "isunitary" begin
    g = Rx(0.1 + 0im)
    @test @test_nowarn isunitary(g) == true

    g = Rx(0.1 + 1im)
    @test @test_logs (
        :warn,
        "θ in RotationGate is not real, got θ=$(g.theta), fallback to matrix-based method",
    ) isunitary(g) == false
end
