using Test
using YaoBlocks
using YaoArrayRegister
using LinearAlgebra

@testset "basic error channels" begin
    dm = rand_density_matrix(3)
    ch = phase_flip_channel(3, (1, ); p=0.2)
    opZ = mat(put(3, 1=>Z))
    @test 0.2 * dm.state + 0.8 * opZ * dm.state * opZ ≈ apply(dm, ch).state

    dm = rand_density_matrix(3)
    ch = bit_flip_channel(3, (1, ); p=0.2)
    opX = mat(put(3, 1=>X))
    @test 0.2 * dm.state + 0.8 * opX * dm.state * opX ≈ apply(dm, ch).state

    dm = rand_density_matrix(3)
    ch = depolarizing_channel(3;p=0.2)
    @test (0.8 * dm.state + 0.1 * IMatrix(1<<3)) ≈ apply(dm, ch).state

    # cumulated channel
    ch1 = phase_flip_channel(3, (1, 2); p=0.2)
    ch2 = chain(phase_flip_channel(3, (1, ); p=0.2), phase_flip_channel(3, (2, ); p=0.2))
    dm = rand_density_matrix(3)
    @test apply(dm, ch1) ≈ apply(dm, ch2)

    ch1 = bit_flip_channel(3, (1, 2); p=0.2)
    ch2 = chain(bit_flip_channel(3, (1, ); p=0.2), bit_flip_channel(3, (2, ); p=0.2))
    dm = rand_density_matrix(3)
    @test apply(dm, ch1) ≈ apply(dm, ch2)
end

@testset "pauli channel" begin
    dm = rand_density_matrix(3)
    ch = pauli_error_channel(3, (1, );pz=0.2, py=0.1, px=0.3)
    opX = mat(put(3, 1=>X))
    opY = mat(put(3, 1=>Y))
    opZ = mat(put(3, 1=>Z))

    @test 0.4 * dm.state + 0.3 * opX * dm.state * opX + 
        0.1 * opY * dm.state * opY +
        0.2 * opZ * dm.state * opZ ≈ apply(dm, ch).state


    dm = rand_density_matrix(3)
    ch1 = pauli_error_channel(3, (1, 2);pz=0.2, py=0.1, px=0.3)
    ch2 = chain(
        pauli_error_channel(3, (1, );pz=0.2, py=0.1, px=0.3),
        pauli_error_channel(3, (2, );pz=0.2, py=0.1, px=0.3)
    )
    @test apply(dm, ch1) ≈ apply(dm, ch2)

end
