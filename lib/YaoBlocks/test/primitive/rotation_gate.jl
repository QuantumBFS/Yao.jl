using Test, YaoBlocks, YaoArrayRegister
using YaoBlocks.ConstGate: CNOT

@testset "test constructor" for T in [Float16, Float32, Float64]
    # NOTE: type should follow the axis
    @test RotationGate(X, 0.1) isa PrimitiveBlock{2}

    @test Rx(1) isa RotationGate{2,Float64,XGate}
    @test Rx(T(0.1)) isa RotationGate{2,T,XGate}
    @test Ry(T(0.1)) isa RotationGate{2,T,YGate}
    @test Rz(T(0.1)) isa RotationGate{2,T,ZGate}
end

@testset "test matrix" begin
    theta = 2.0
    for (DIRECTION, MAT) in [
        (X, [cos(theta / 2) -im*sin(theta / 2); -im*sin(theta / 2) cos(theta / 2)]),
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
    x = Rx(0.1)
    @test dispatch(x, 3.0f0) == Rx(3.0f0) &&
          eltype(getiparams(dispatch(x, 3.0f0))) == Float32
    @test x == Rx(0.1)
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

@testset "isunitary, isdiagonal" begin
    g = Rx(0.1 + 0im)
    @test @test_nowarn isunitary(g) == true

    g = Rx(0.1 + 1im)
    @test @test_logs (
        :warn,
        "θ in RotationGate is not real, got θ=$(g.theta), fallback to matrix-based method",
    ) isunitary(g) == false

    @test isdiagonal(rot(Z, 0.5))
    @test !isdiagonal(rot(X, 0.5))
end

@testset "occupied locs" begin
    g = rot(put(5, 2 => X), 0.5)
    @test occupied_locs(g) == (2,)
end

@testset "instruct_get_element" begin
    pb = rot(Y, 0.4)
    mpb = mat(pb)
    allpass = true
    for i=basis(pb), j=basis(pb)
        allpass &= pb[i, j] == mpb[Int(i)+1, Int(j)+1]
    end
    @test allpass
end

@testset "instruct_get_element" begin
    for pb in [Rx(0.5), rot(SWAP, 0.5), shift(0.5), phase(0.5)
            ]
        mpb = mat(pb)
        allpass = true
        for i=basis(pb), j=basis(pb)
            allpass &= pb[i, j] == mpb[Int(i)+1, Int(j)+1]
        end
        @test allpass

        allpass = true
        for j=basis(pb)
            allpass &= vec(pb[:, j]) == mpb[:, Int(j)+1]
            allpass &= vec(pb[j,:]) == mpb[Int(j)+1,:]
            allpass &= isclean(pb[:,j])
        end
        @test allpass
    end
end