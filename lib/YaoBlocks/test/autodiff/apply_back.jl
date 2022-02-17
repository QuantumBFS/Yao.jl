using Test
using YaoBlocks.AD
using YaoBlocks, YaoArrayRegister
using Random

@testset "apply put" begin
    Random.seed!(5)
    for reg0 in [rand_state(3), rand_state(3, nbatch = 10)]
        # put block, diagonal
        @test test_apply_back(reg0, put(3, 1 => shift(0.5)), 0.5; δ = 1e-5)
        @test test_apply_back(reg0, control(3, (2, 3), 1 => Rz(0.5)), 0.5; δ = 1e-5)
        @test test_apply_back(reg0, control(3, 2, 1 => shift(0.5)), 0.5; δ = 1e-5)
        # dense matrix
        @test test_apply_back(reg0, put(3, 1 => cache(Rx(0.5))), 0.5; δ = 1e-5)
        @test test_apply_back(
            reg0,
            put(3, 1 => chain(Rz(0.5), Rx(0.8))),
            [0.5, 0.8];
            δ = 1e-5,
        )
        @test test_apply_back(reg0, control(3, (2, 3), 1 => Rx(0.5)), 0.5; δ = 1e-5)
        # sparse matrix csc
        @test test_apply_back(reg0, put(3, (1, 2) => rot(SWAP, 0.5)), 0.5; δ = 1e-5)
        @test test_apply_back(
            reg0,
            control(3, (3,), (1, 2) => rot(SWAP, 0.5)),
            0.5;
            δ = 1e-5,
        )

        # special cases: DiffBlock
        @test test_apply_back(reg0, put(3, 1 => Rz(0.5)), 0.5; δ = 1e-5)
        @test test_apply_back(reg0, put(3, 1 => Rx(0.5)), 0.5; δ = 1e-5)
        @test test_apply_back(rand_state(1), Rx(0.0), 0.5; δ = 1e-5)

        # TimeEvolution
        @test test_apply_back(reg0, TimeEvolution(put(3, 1 => X), 0.5), 0.5; δ = 1e-5)

        # scale
        @test test_apply_back(reg0, Scale(3.0, put(3, 1 => X)), 3.5; δ = 1e-5)
        @test test_apply_back(reg0, Scale(3.0, put(3, 1 => Scale(2.0,Y))), [1.3, 0.6]; δ = 1e-5)
        @test test_apply_back(reg0, chain(Scale(2.0, repeat(3,X)), Scale(3.0, put(3, 1 => Scale(2.0,Y)))), [-0.4, 2.0, -0.2]; δ = 1e-5)
    end
end

@testset "apply chain" begin
    Random.seed!(5)
    for reg0 in [rand_state(3), rand_state(3, nbatch = 10)]
        @test test_apply_back(
            reg0,
            chain(3, put(3, 1 => shift(0.0)), control(3, (2, 3), 1 => Rz(0.0))),
            [0.5, 0.5];
            δ = 1e-5,
        )
        c = chain(3, put(3, 1 => shift(0.0)), NoParams(control(3, (2, 3), 1 => Rz(0.0))))
        @test nparameters(c) == 1
        @test test_apply_back(reg0, c, 0.5; δ = 1e-5)
    end
end

@testset "apply dagger, scale" begin
    Random.seed!(5)
    for reg0 in [rand_state(3), rand_state(3, nbatch = 10)]
        @test test_apply_back(
            reg0,
            chain(put(3, 1 => Rx(0.0)), 3.0 * control(3, (2, 3), 1 => Rz(0.0))),
            [0.5, 1.5, 0.6];
            δ = 1e-5,
        )
        @test test_apply_back(reg0, Daggered(put(3, 1 => Rx(0.0))), 0.5; δ = 1e-5)
        @test test_apply_back(
            reg0,
            control(3, (2, 3), 1 => Daggered(Rz(0.0))),
            0.5;
            δ = 1e-5,
        )
        @test test_apply_back(
            reg0,
            chain(
                3,
                Daggered(put(3, 1 => Rx(0.0))),
                control(3, (2, 3), 1 => Daggered(Rz(0.0))),
            ),
            [0.5, 0.5];
            δ = 1e-5,
        )
    end
end

@testset "apply subroutine" begin
    Random.seed!(5)
    for reg0 in [rand_state(3), rand_state(3, nbatch = 10)]
        @test test_apply_back(
            reg0,
            chain(
                3,
                put(3, 1 => Rx(0.0)),
                subroutine(3, control(2, 2, 1 => shift(0.0)), (3, 1)),
            ),
            [0.5, 0.5];
            δ = 1e-5,
        )
    end
end

@testset "apply kron repeated" begin
    Random.seed!(5)
    for reg0 in [rand_state(3), rand_state(3, nbatch = 10)]
        @test test_apply_back(
            reg0,
            chain(3, put(3, 1 => Rx(0.0)), kron(Rx(0.4), Y, Rz(0.5))),
            [0.5, 0.3, 0.8];
            δ = 1e-5,
        )
        @test test_apply_back(
            reg0,
            chain(repeat(3, Rx(0.5), 1:2), repeat(3, Ry(0.6), 2:3)),
            [0.5, 0.8];
            δ = 1e-5,
        )
        @test test_apply_back(
            reg0,
            chain(repeat(3, H, 1:2), repeat(3, Ry(0.6), 2:3)),
            [0.8];
            δ = 1e-5,
        )
    end
end

@testset "apply Add" begin
    # + is not reversible
    for reg0 in [rand_state(3), rand_state(3, nbatch = 10)]
        @test_broken test_apply_back(
            reg0,
            0.2 * (3.0 * control(3, (2, 3), 1 => Rz(0.0)) + put(3, 2 => Rx(0.0))),
            [0.5, 0.9, 0.6, 0.1];
            δ = 1e-5,
            in = copy(reg0),
        )
    end
end
