using Compat.Test

import QuCircuit: X, Y, Z, Hadmard, Gate, PhiGate, RotationGate
import QuCircuit: rand_state, state, focus!
# interface
import QuCircuit: gate, phase, rot
# Block Trait
import QuCircuit: nqubit, ninput, noutput, isunitary, ispure
# Required Methods
import QuCircuit: apply!, dispatch!

@testset "Constant Gates" begin

    # default dtype is Complex128/ComplexF64
    @test gate(X) == Gate{1, X, Complex128}()
    @test gate(Y) == Gate{1, Y, Complex128}()
    @test gate(Z) == Gate{1, Z, Complex128}()
    @test gate(Hadmard) == Gate{1, Hadmard, Complex128}()

    @test gate(Complex64, X) == Gate{1, X, Complex64}()

    # properties
    g = gate(X)
    @test nqubit(g) == 1
    @test ninput(g) == 1
    @test noutput(g) == 1
    @test isunitary(g) == true
    @test ispure(g) == true

    reg = rand_state(4)
    focus!(reg, 1)
    # gates will be applied to register (by matrix multiplication)
    # without any conversion by default
    @test [0 1;1 0] * state(reg) == state(apply!(reg, g))
    focus!(reg, 1:4) # back to vector
    @test_throws DimensionMismatch apply!(reg, g)

    # check matrixes
    for (NAME, MAT) in [
        (X, [0 1;1 0]),
        (Y, [0 -im; im 0]),
        (Z, [1 0;0 -1]),
        (Hadmard, (elem = 1 / sqrt(2); [elem elem; elem -elem])),
    ]
        for DTYPE in [Compat.ComplexF16, Compat.ComplexF32, Compat.ComplexF64]
            @test full(gate(DTYPE, NAME)) == Array{DTYPE, 2}(MAT)

            # all constant gates share the same constant matrix
            @test full(gate(DTYPE, NAME)) === full(gate(DTYPE, NAME))
            @test sparse(gate(DTYPE, NAME)) === sparse(gate(DTYPE, NAME))
        end
    end

    # check compare method
    # TODO: traverse all possible value
    @test (gate(X) == gate(X)) == true
    @test (gate(X) == gate(Y)) == false
    @test (gate(Z) == gate(X)) == false
end

@testset "Phase Gate" begin

    @test phase(-pi).theta == -pi
    # default is Float64
    @test typeof(phase(pi)) == PhiGate{Float64}
    # will not accept non-real parameters
    @test_throws MethodError phase(Complex64, 2.0)

    # properties
    g = phase(pi)
    @test nqubit(g) == 1
    @test ninput(g) == 1
    @test noutput(g) == 1
    @test isunitary(g) == true
    @test ispure(g) == true

    @test full(g) == exp(im * pi) * [exp(-im * pi) 0; 0  exp(im * pi)]
    @test copy(g) !== g # deep copy
    @test dispatch!(g, 2.0).theta == 2.0

    # compare methods

    @test (phase(2.0) == phase(2.0)) == true
    @test (phase(2.0) == phase(1.0)) == false
end


@testset "Rotation Gate" begin

    @test rot(X, 2.0).theta == 2.0
    @test typeof(rot(X, 2.0)) == RotationGate{X, Float64}

    # properties
    g = rot(X, 2.0)
    @test nqubit(g) == 1
    @test ninput(g) == 1
    @test noutput(g) == 1
    @test isunitary(g) == true
    @test ispure(g) == true


    theta = 2.0
    for (DIRECTION, MAT) in [
        (X, [cos(theta/2) -im*sin(theta/2); -im*sin(theta/2) cos(theta/2)]),
        (Y, [cos(theta/2) -sin(theta/2); sin(theta/2) cos(theta/2)]),
        (Z, [exp(-im*theta/2) 0;0 exp(im*theta/2)])
    ]
        @test full(rot(DIRECTION, theta)) == MAT
    end

    @test copy(g) !== g # deep copy
    @test dispatch!(g, 1.0).theta == 1.0

    # compare method
    @test (rot(X, 2.0) == rot(X, 2.0)) == true
    @test (rot(X, 2.0) == rot(Y, 2.0)) == false
    @test (rot(X, 2.0) == rot(X, 1.0)) == false
end
