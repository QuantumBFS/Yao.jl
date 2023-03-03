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
