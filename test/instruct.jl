using Test, YaoArrayRegister, LuxurySparse

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
