using Test, YaoBlocks, LuxurySparse, BitBasis, YaoBlocks.ConstGate

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

    for (
        each,
        MAT,
    ) in [
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
        @test @allocated(mat(X)) == 0
        @test @allocated(mat(ComplexF32, X)) > 0
        @const_gate X::ComplexF32
        @test @allocated(mat(ComplexF32, XGate())) == 0
    end

    @testset "define new" begin
        @const_gate TEST = rand(ComplexF64, 2, 2)

        # errors if given matrix is not a square matrix
        @test_throws DimensionMismatch @const_gate TEST::ComplexF32 = rand(2, 3)

        @const_gate TEST::ComplexF32
        @test @allocated(mat(ComplexF32, TEST)) == 0
    end

end

@testset "I gate" begin
    g = ConstGate.IGate{2}()
    @test mat(g) ≈ IMatrix{4,ComplexF64}()
    @test ishermitian(g)
    @test isunitary(g)
end

@testset "test adjoints" begin
    adjoint(Pu) == Pd
    adjoint(Pd) == Pu
end
