using Test, YaoBlocks, YaoArrayRegister

@testset "test constructor" for T in [Float16, Float32, Float64]
    # NOTE: type should follow the axis
    @test RotationGate(X(Complex{T}), 0.1) isa PrimitiveBlock{1, Complex{T}}
    @test RotationGate(X(Complex{T}), 0.1) isa RotationGate{1, T, XGate{Complex{T}}}
    @test_throws TypeError RotationGate{1, T, XGate{Complex{T}}} # will not accept non-real type

    @test Rx(T(0.1)) isa RotationGate{1, T, XGate{Complex{T}}}
    @test Ry(T(0.1)) isa RotationGate{1, T, YGate{Complex{T}}}
    @test Rz(T(0.1)) isa RotationGate{1, T, ZGate{Complex{T}}}
end

@testset "test matrix" begin
    theta = 2.0
    for (DIRECTION, MAT) in [
        (X, [cos(theta/2) -im*sin(theta/2); -im*sin(theta/2) cos(theta/2)]),
        (Y, [cos(theta/2) -sin(theta/2); sin(theta/2) cos(theta/2)]),
        (Z, [exp(-im*theta/2) 0;0 exp(im*theta/2)]),
        (CNOT, exp(-mat(CNOT)/2*theta*im |> Matrix)),
        (control(2, (1,), 2=>X), exp(-mat(CNOT)/2*theta*im |> Matrix))]

        @test mat(RotationGate(DIRECTION, theta)) ≈ MAT
    end
end

@testset "test dispatch" begin
    @test dispatch!(Rx(0.1), 0.3) == Rx(0.3)

    @testset "test $op" for op in [+, -, *, /]
        @test dispatch!(op, Rx(0.1), π) == Rx(op(0.1, π))
    end

    @test_throws AssertionError dispatch!(Rx(0.1), (0.2, 0.3))
end
