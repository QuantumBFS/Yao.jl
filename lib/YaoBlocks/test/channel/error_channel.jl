using Test
using YaoBlocks
using YaoArrayRegister
using LinearAlgebra

@testset "basic error channels" begin
    dm = rand_density_matrix(3)
    ch = put(3, 1 => phase_flip_channel(0.2))
    opZ = mat(put(3, 1=>Z))
    @test 0.8 * dm.state + 0.2 * opZ * dm.state * opZ ≈ apply(dm, ch).state

    dm = rand_density_matrix(3)
    ch = put(3, 1 => bit_flip_channel(0.2))
    opX = mat(put(3, 1=>X))
    @test 0.8 * dm.state + 0.2 * opX * dm.state * opX ≈ apply(dm, ch).state

    dm = rand_density_matrix(3)
    ch = depolarizing_channel(3; p=0.2)
    @test (0.8 .* dm.state .+ (0.2 / 2^3) .* IMatrix(1<<3)) ≈ apply(dm, ch).state

    dm = rand_density_matrix(3)
    ch = depolarizing_channel(3, p=1.)
    @test apply(dm, ch).state ≈ IMatrix(1<<3) ./ 2^3

    dm = rand_density_matrix(1)
    ch1 = put(1, 1 => single_qubit_depolarizing_channel(0.1))
    ch2 = depolarizing_channel(1, p=0.1)
    @test apply(dm, ch1) ≈ apply(dm, ch2)

    dm = rand_density_matrix(2)
    ch1 = put(2, (1, 2) => two_qubit_depolarizing_channel(0.1))
    ch2 = depolarizing_channel(2, p=0.1)
    @test apply(dm, ch1) ≈ apply(dm, ch2)
end

@testset "pauli channel" begin
    dm = rand_density_matrix(3)
    ch = put(3, 1 => pauli_error_channel(pz=0.2, py=0.1, px=0.3))
    opX = mat(put(3, 1=>X))
    opY = mat(put(3, 1=>Y))
    opZ = mat(put(3, 1=>Z))

    @test 0.4 * dm.state + 0.3 * opX * dm.state * opX + 
        0.1 * opY * dm.state * opY +
        0.2 * opZ * dm.state * opZ ≈ apply(dm, ch).state
end

@testset "super operators and kraus operators" begin
    # bit flip
    p_error = 0.05
    bit_flip = BitFlipError(p_error)
    @test SuperOp(bit_flip).superop ≈ [0.95 0.0 0.0 0.05;
        0.0 0.95 0.05 0.0;
        0.0 0.05 0.95 0.0;
        0.05 0.0 0.0 0.95]
    bit_flip_kraus = KrausChannel(bit_flip)
    # Note: the phase of the matrix can be arbitrary, so we only check the magnitude
    @test mat(bit_flip_kraus.operators[1]) ≈ [sqrt(0.95) 0.0; 0.0 sqrt(0.95)]
    @test mat(bit_flip_kraus.operators[2]) ≈ [0.0 sqrt(0.05); sqrt(0.05) 0.0]

    # phase flip
    p_error = 0.05
    phase_flip = PhaseFlipError(p_error)
    @test SuperOp(phase_flip).superop ≈ [1.0 0.0 0.0 0.0;
        0.0 0.9 0.0 0.0;
        0.0 0.0 0.9 0.0;
        0.0 0.0 0.0 1.0]

    phase_flip_kraus = KrausChannel(phase_flip)
    @test mat(phase_flip_kraus.operators[1]) ≈ [sqrt(0.95) 0.0; 0.0 sqrt(0.95)]
    @test mat(phase_flip_kraus.operators[2]) ≈ [sqrt(0.05) 0.0; 0.0 -sqrt(0.05)]

    # depolarizing
    p_error = 0.1
    depolarizing = DepolarizingError(p_error)
    @test SuperOp(depolarizing).superop ≈ [0.95 0.0 0.0 0.05;
        0.0 0.9 0.0 0.0;
        0.0 0.0 0.9 0.0;
        0.05 0.0 0.0 0.95]

    depolarizing_kraus = KrausChannel(depolarizing)
    function effectively_same(a, b)
        res = a * a' ≈ b * b'
        if !res
            println("a: ", a)
            println("b: ", b)
        end
        res
    end
    @test effectively_same(mat(depolarizing_kraus.operators[1]), [-sqrt(0.925) 0.0; 0.0 -sqrt(0.925)])
    @test effectively_same(mat(depolarizing_kraus.operators[2]), [-sqrt(0.025) 0.0; 0.0 sqrt(0.025)])
    @test effectively_same(mat(depolarizing_kraus.operators[3]), [0.0 -sqrt(0.025)*im; sqrt(0.025)*im 0.0])
    @test effectively_same(mat(depolarizing_kraus.operators[4]), [0.0 sqrt(0.025); sqrt(0.025) 0.0])

    # reset
    p_error = 0.1
    reset = ResetError(p_error, p_error)
    reset_kraus = KrausChannel(reset)
    @test SuperOp(reset_kraus).superop ≈ [0.9 0 0 0.1; 0 0.8 0 0; 0 0 0.8 0; 0.1 0 0 0.9]

    # NOTE: this is not the simplest form of Kraus operators for reset channel!!
    @test mat(reset_kraus.operators[1]) ≈ [sqrt(0.8) 0.0; 0.0 sqrt(0.8)]
    @test mat(reset_kraus.operators[2]) ≈ [sqrt(0.1) 0.0; 0.0 0.0]
    @test mat(reset_kraus.operators[3]) ≈ [0.0 0.0; sqrt(0.1) 0.0]
    @test mat(reset_kraus.operators[4]) ≈ [0.0 0.0; 0.0 sqrt(0.1)]
    @test mat(reset_kraus.operators[5]) ≈ [0.0 sqrt(0.1); 0.0 0.0]
end