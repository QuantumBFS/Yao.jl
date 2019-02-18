using Test, YaoBase, YaoArrayRegister, LuxurySparse

@testset "test general unitary instruction" begin
    U1 = randn(ComplexF64, 2, 2)
    ST = randn(ComplexF64, 1<<4)
    II = IMatrix(2)
    M = kron(II, U1, II, II) * ST

    @test instruct!(copy(ST), U1, 3) ≈ M ≈ instruct!(reshape(copy(ST), :, 1), U1, 3)

    U2 = rand(ComplexF64, 4, 4)
    M = kron(II, U2, II) * ST
    @test instruct!(copy(ST), U2, (2, 3)) ≈ M

    @test instruct!(copy(ST), kron(U1, U1), (3, 1)) ≈ instruct!(instruct!(copy(ST), U1, 3), U1, 1)
    @test instruct!(reshape(copy(ST), :, 1), kron(U1, U1), (3, 1)) ≈
        instruct!(instruct!(reshape(copy(ST), :, 1), U1, 3), U1, 1)
end


@testset "test general control unitary operator" begin
    P0 = ComplexF64[1 0;0 0]
    P1 = ComplexF64[0 0;0 1]
    Z  = ComplexF64[1 0;0 -1]

    ST = randn(ComplexF64, 1<<5)
    U1 = randn(ComplexF64, 2,2)
    instruct!(copy(ST), U1, (3, ), (1, ), (1, ))

    @test instruct!(copy(ST), U1, (3, ), (1, ), (1, )) ≈
        general_controlled_gates(5, [P1], [1], [U1], [3]) * ST
    @test instruct!(copy(ST), U1, (3, ), (1, ), (0, )) ≈
        general_controlled_gates(5, [P0], [1], [U1], [3]) * ST

    # control U2
    U2 = kron(U1, U1)
    @test instruct!(copy(ST), U2, (3, 4), (1, ), (1, )) ≈ general_controlled_gates(5, [P1], [1], [U2], [3]) * ST

    # multi-control U2
    @test instruct!(copy(ST), U2, (3, 4), (5, 1), (1, 0)) ≈ general_controlled_gates(5, [P1, P0], [5, 1], [U2], [3]) * ST
end
