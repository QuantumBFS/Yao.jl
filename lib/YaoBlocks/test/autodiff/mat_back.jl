using Test
using YaoBlocks.AD, YaoBlocks
using YaoArrayRegister
using Random
using YaoArrayRegister: rand_unitary

using SparseArrays, LuxurySparse, LinearAlgebra

@testset "mat rot/shift/phase/scale" begin
    Random.seed!(5)
    for G in [X, Y, Z, ConstGate.SWAP, ConstGate.CZ, ConstGate.CNOT]
        @test test_mat_back(ComplexF64, rot(G, 0.0), 0.5; δ = 1e-5)
    end

    for G in [ShiftGate, PhaseGate]
        @test test_mat_back(ComplexF64, G(0.0), 0.5; δ = 1e-5)
    end

    G = time_evolve(put(3, 2 => X), 0.0)
    @test test_mat_back(ComplexF64, G, 0.5; δ = 1e-5)

    # NOTE: inputs of chain blocks must be unitary!
    G = 5.0 * matblock(rand_unitary(2))
    @test test_mat_back(ComplexF64, G, 0.5; δ = 1e-5)
    G = chain(Rx(0.5), Val(1.0im) * matblock(rand_unitary(2)), Ry(0.5))
    @test test_mat_back(ComplexF64, G, [0.1, 0.2]; δ = 1e-5)
    G = chain(Rx(0.5), 1.0 * matblock(rand_unitary(2)), Ry(0.5))
    @test test_mat_back(ComplexF64, G, [0.1, -1.0, 1.0]; δ = 1e-5)
    G = chain(Rx(0.5), 1.0 * Rx(0.6), Ry(0.5))
    @test test_mat_back(ComplexF64, G, [0.3, -1.0, 0.4, 1.0]; δ = 1e-5)
end

@testset "mat put block, control block" begin
    Random.seed!(5)
    for use_outeradj in [false, true]
        # put block, diagonal
        @test test_mat_back(
            ComplexF64,
            put(3, 1 => chain(Rz(0.5), Ry(0.9), Rz(0.3))),
            [0.5, 0.9, 0.3];
            δ = 1e-5,
            use_outeradj = use_outeradj,
        )
        @test test_mat_back(
            ComplexF64,
            put(3, 1 => Rz(0.5)),
            0.5;
            δ = 1e-5,
            use_outeradj = use_outeradj,
        )
        @test test_mat_back(
            ComplexF64,
            control(3, (2, 3), 1 => Rz(0.5)),
            0.5;
            δ = 1e-5,
            use_outeradj = use_outeradj,
        )
        # dense matrix
        @test test_mat_back(
            ComplexF64,
            put(3, 1 => Rx(0.5)),
            0.5;
            δ = 1e-5,
            use_outeradj = use_outeradj,
        )
        @test test_mat_back(
            ComplexF64,
            control(3, (2, 3), 1 => Rx(0.5)),
            0.5;
            δ = 1e-5,
            use_outeradj = use_outeradj,
        )
        # sparse matrix csc
        @test test_mat_back(
            ComplexF64,
            put(3, (1, 2) => rot(SWAP, 0.5)),
            0.5;
            δ = 1e-5,
            use_outeradj = use_outeradj,
        )
        @test test_mat_back(
            ComplexF64,
            control(3, (3,), (1, 2) => rot(SWAP, 0.5)),
            0.5;
            δ = 1e-5,
            use_outeradj = use_outeradj,
        )
    end

    # is permatrix even possible?
    #@test test_mat_back(ComplexF64, put(3, 1=>matblock(pmrand(2))), [0.5, 0.6]; δ=1e-5)
    # ignore identity matrix.
end

@testset "mat subroutine" begin
    Random.seed!(5)
    @test test_mat_back(
        ComplexF64,
        subroutine(3, control(2, 2, 1 => shift(0.0)), (3, 1)),
        0.5;
        δ = 1e-5,
    )
end

@testset "mat chain" begin
    Random.seed!(5)
    @test test_mat_back(ComplexF64, chain(3, control(3, 2, 1 => shift(0.0))), 0.5; δ = 1e-5)
    @test test_mat_back(
        ComplexF64,
        chain(3, put(3, 2 => X), control(3, 2, 1 => shift(0.0))),
        0.5;
        δ = 1e-5,
    )
    @test test_mat_back(
        ComplexF64,
        chain(3, control(3, 2, 1 => shift(0.0)), put(3, 2 => X)),
        0.5;
        δ = 1e-5,
    )
    @test test_mat_back(
        ComplexF64,
        chain(3, control(3, 2, 1 => shift(0.0)), NoParams(put(3, 1 => Rx(0.0)))),
        0.5;
        δ = 1e-5,
    )
    @test test_mat_back(
        ComplexF64,
        chain(
            3,
            control(3, 2, 1 => shift(0.0)),
            chain(put(3, 1 => Rx(0.0)), put(3, 2 => Ry(0.0))),
        ),
        [0.5, 0.5, 0.5];
        δ = 1e-5,
    )
    @test test_mat_back(
        ComplexF64,
        chain(3, chain(3, put(3, 1 => Rx(0.0)), put(3, 2 => Ry(0.0)))),
        [0.5, 0.5];
        δ = 1e-5,
    )
end

@testset "mat kron" begin
    use_outeradj = false
    @test test_mat_back(
        ComplexF64,
        kron(Rx(0.5), Rz(0.6)),
        [0.5, 0.5];
        δ = 1e-5,
        use_outeradj = use_outeradj,
    )
end
