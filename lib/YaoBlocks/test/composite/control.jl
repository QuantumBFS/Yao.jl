using Test, YaoBlocks, YaoArrayRegister, LuxurySparse, BitBasis
using YaoBlocks.ConstGate

U = mat(X)
⊗ = kron

@testset "construct" begin
    @test_throws DimensionMismatch control(3, 2, 1 => swap(2, 1, 2))
    @test_throws MethodError control(3, 1, 2:3 => rand(4, 4))
    @test_throws LocationConflictError control(3, 2, (1, 2) => swap(2, 1, 2))

    @test cnot(4, (1, 2), 3) == control(4, (1, 2), 3 => X)
    @test cnot((1, 2), 3)(4) == cnot(4, (1, 2), 3) # curried version

    @test cz(4, (1, 2), 3) == control(4, (1, 2), 3 => Z)
    @test cz((1, 2), 3)(4) == cz(4, (1, 2), 3)

    @test control((1, 2), 3 => X)(4) == control(4, (1, 2), 3 => X)
end

@testset "single control" begin
    g = ControlBlock(2, (1,), X, (2,))
    @test nqubits(g) == 2
    m = IMatrix(U) ⊗ mat(P0) + U ⊗ mat(P1)
    @test mat(g) == m
end

@testset "single control with inferred size" begin
    g = ControlBlock(3, (2,), X, (3,))
    @test nqubits(g) == 3
    m = (IMatrix(U) ⊗ mat(P0) + U ⊗ mat(P1)) ⊗ mat(I2)
    @test mat(g) == m
end

@testset "control with fixed size" begin
    g = ControlBlock(4, (2,), X, (3,))
    @test nqubits(g) == 4
    m = mat(I2) ⊗ (IMatrix(U) ⊗ mat(P0) + U ⊗ mat(P1)) ⊗ mat(I2)
    @test mat(g) == m
end

@testset "control with blank" begin
    g = ControlBlock(4, (3,), X, (2,))
    @test nqubits(g) == 4

    m = mat(I2) ⊗ (mat(P0) ⊗ IMatrix(U) + mat(P1) ⊗ U) ⊗ mat(I2)
    @test mat(g) == m
end

@testset "multi control" begin
    g = ControlBlock(4, (2, 3), X, (4,))
    @test nqubits(g) == 4

    op = IMatrix(U) ⊗ mat(P0) + U ⊗ mat(P1)
    op = IMatrix(op) ⊗ mat(P0) + op ⊗ mat(P1)
    op = op ⊗ mat(I2)
    @test mat(g) == op
end

@testset "multi control with blank" begin
    g = ControlBlock(7, (6, 4, 2), X, (3,)) # -> [2, 4, 6]
    @test nqubits(g) == 7
    @test occupied_locs(g) == (6, 4, 2, 3)

    op = IMatrix(U) ⊗ mat(P0) + U ⊗ mat(P1) # 2, 3
    op = mat(P0) ⊗ IMatrix(op) + mat(P1) ⊗ op # 2, 3, 4
    op = mat(P0) ⊗ mat(I2) ⊗ IMatrix(op) + mat(P1) ⊗ mat(I2) ⊗ op # 2, 3, 4, blank, 6
    op = op ⊗ mat(I2) # blank, 2, 3, blank, 4, 6
    op = mat(I2) ⊗ op # blnak, 2, 3, blank, 4, 6, blank

    @test mat(g) == op
end

@testset "inverse control" begin
    g = ControlBlock(2, (1,), (0,), X, (2,))
    op = U ⊗ mat(P0) + IMatrix(U) ⊗ mat(P1)
    @test mat(g) ≈ op
end

@testset "control two-bit gate" begin
    @test_throws DimensionMismatch ControlBlock(3, (1,), CNOT, (2,))
    g = ControlBlock(3, (1,), CNOT, (2, 3))
    @test applymatrix(g) ≈ mat(Toffoli)
    @test occupied_locs(g) == (1, 2, 3)
    g = ControlBlock(3, (3,), CNOT, (2, 1))
    @test applymatrix(g) ≈ mat(Toffoli) |> invorder
    @test occupied_locs(g) == (3, 2, 1)
    g = ControlBlock(3, (2,), CNOT, (3, 1))
    g2 = PutBlock(3, Toffoli, (3, 2, 1))
    g3 = ControlBlock(3, (3, 2), X, (1,))
    @test applymatrix(g) == applymatrix(g2) == applymatrix(g3)
    @test mat(g) == mat(g2)
    @test mat(g) == mat(g3)
end

@testset "push tests" begin
    @test !iscommute(control(5, 1, 2=>X), control(5, 1, 2=>Y))
    @test iscommute(control(5, 1, 2=>X), control(5, 1, 3=>Y))
    @test !iscommute(control(5, 1, 2=>X), control(5, 2, 3=>Y))

    c = control((2,3), 1=>X)(5)
    @test c == control(5, (2,3), 1=>X)
    @test copy(c) == c
end