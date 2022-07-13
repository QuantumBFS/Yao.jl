using Test
using YaoBlocks
using YaoArrayRegister
using LinearAlgebra

@testset "basic error channels" begin
    dm = rand_density_matrix(3)
    ch = phase_flip_channel(3, 0.2, (1, 2))
    opZ = mat(repeat(3, Z, (1, 2)))
    @test 0.2 * dm.state + 0.8 * opZ * dm.state * opZ ≈ apply(dm, ch).state

    dm = rand_density_matrix(3)
    ch = bit_flip_channel(3, 0.2, (1, 2))
    opX = mat(repeat(3, X, (1, 2)))
    @test 0.2 * dm.state + 0.8 * opX * dm.state * opX ≈ apply(dm, ch).state

    dm = rand_density_matrix(3)
    ch = depolarizing_channel(3, 0.2)
    @test (0.8 * dm.state + 0.1 * IMatrix(1<<3)) ≈ apply(dm, ch).state
end
