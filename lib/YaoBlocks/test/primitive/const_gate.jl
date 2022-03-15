using Test, YaoBlocks, LuxurySparse, BitBasis, YaoBlocks.ConstGate
using LinearAlgebra

@testset "test builtin gates" begin

    @testset "test $each" for each in [X, Y, Z, H, CNOT, SWAP, Toffoli]
        @test isunitary(each) == true
        @test isreflexive(each) == true
        @test ishermitian(each) == true
    end


    @testset "test $each nqubits" for each in [X, Y, Z, H, T, S, Tdag, Sdag, P0, P1, Pu, Pd]
        @test nqubits(each) == 1
    end

    @testset "test $each" for each in [S, T]
        @test isunitary(each)
        @test isreflexive(each) == false
        @test ishermitian(each) == false
    end

    @testset "test $each" for each in [P0, P1]
        @test isunitary(each) == false
        @test isreflexive(each) == false
        @test ishermitian(each) == true
    end

    @testset "test $each" for each in [Pu, Pd]
        @test isunitary(each) == false
        @test isreflexive(each) == false
        @test ishermitian(each) == false
    end

    @test nqubits(CNOT) == 2
    @test nqubits(CZ) == 2
    @test nqubits(SWAP) == 2
    @test nqubits(Toffoli) == 3


end

@testset "matrix" begin
    CNOT_R = PermMatrix([1, 2, 4, 3], ones(ComplexF64, 4))
    Toffoli_R = PermMatrix([1, 2, 3, 4, 5, 6, 8, 7], ones(ComplexF64, 8))

    for (each, MAT) in [
        (X, [0 1; 1 0]),
        (Y, [0 -im; im 0]),
        (Z, [1 0; 0 -1]),
        (H, (elem = 1 / sqrt(2); [elem elem; elem -elem])),
    ]
        @test mat(each) ≈ MAT

    end
    @test mat(CNOT) |> invorder == CNOT_R
    @test mat(Toffoli) |> invorder == Toffoli_R
    @test mat(T) * mat(T) ≈ mat(S)

    @test mat(T)' ≈ mat(T')
    @test mat(Tdag)' ≈ mat(Tdag')
    @test T' isa TdagGate
    @test Tdag' isa TGate

    @test mat(S)' ≈ mat(S')
    @test mat(Sdag)' ≈ mat(Sdag')
    @test S' isa SdagGate
    @test Sdag' isa SGate
end

@testset "test @const_gate" begin

    @testset "bind new type" begin
        @const_gate X::ComplexF32
        @test mat(ComplexF32, X) isa PermMatrix{ComplexF32}
    end

    @testset "define new" begin
        @const_gate TEST = rand(ComplexF64, 2, 2)

        # errors if given matrix is not a square matrix
        @test_throws DimensionMismatch @const_gate TEST::ComplexF32 = rand(2, 3)
    end

    @testset "define new 3-level" begin
        @const_gate TEST2 = rand(ComplexF64, 3, 3) nlevel=3
        @test nlevel(TEST2) == 3
    end
end

@testset "I gate" begin
    g = ConstGate.IGate{2}()
    @test mat(g) ≈ IMatrix{4,ComplexF64}()
    @test ishermitian(g)
    @test isunitary(g)
end

@testset "test adjoints" begin
    @test adjoint(Pu) == Pd
    @test adjoint(Pd) == Pu
end

@testset "P0/P1" begin
    @test mat(P0) isa Diagonal
    @test mat(P0) ≈ [1 0;0 0]
    @test mat(P1) ≈ [0 0;0 1]
end
