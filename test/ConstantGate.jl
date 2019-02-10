using Test, Random, LinearAlgebra, SparseArrays

using YaoBase, YaoBase.Basis, YaoBlockTree, YaoDenseRegister, LuxurySparse

CNOT_R = PermMatrix([1, 2, 4, 3], ones(ComplexF64, 4))
Toffoli_R = PermMatrix([1, 2, 3, 4, 5, 6, 8, 7], ones(ComplexF64, 8))

@testset "builtins" begin
    for each in [X, Y, Z, H, CNOT, SWAP, Toffoli]
        @test isunitary(each) == true
        @test isreflexive(each) == true
        @test ishermitian(each) == true
    end
    for each in [X, Y, Z, H, T, S, Tdag, Sdag, P0, P1, Pu, Pd]
        @test nqubits(each) == 1
    end
    for each in [S, T]
        @test isunitary(each)
        @test isreflexive(each) == false
        @test ishermitian(each) == false
    end
    for each in [P0, P1]
        @test isunitary(each) == false
        @test isreflexive(each) == false
        @test ishermitian(each) == true
    end
    for each in [Pu, Pd]
        @test isunitary(each) == false
        @test isreflexive(each) == false
        @test ishermitian(each) == false
    end

    @test nqubits(CNOT) == 2
    @test nqubits(SWAP) == 2
    @test nqubits(Toffoli) == 3


    @testset "matrix" begin
        for (each, MAT) in [
            (X, [0 1;1 0]),
            (Y, [0 -im; im 0]),
            (Z, [1 0;0 -1]),
            (H, (elem = 1 / sqrt(2); [elem elem; elem -elem])),
        ]

            @test mat(each) ≈ MAT

        end
        @test mat(CNOT) |> invorder == CNOT_R
        @test mat(Toffoli) |> invorder == Toffoli_R
        @test mat(T)*mat(T) ≈ mat(S)

        @test mat(T)' ≈ mat(T')
        @test mat(Tdag)' ≈ mat(Tdag')
        @test T' isa TdagGate
        @test Tdag' isa TGate

        @test mat(S)' ≈ mat(S')
        @test mat(Sdag)' ≈ mat(Sdag')
        @test S' isa SdagGate
        @test Sdag' isa SGate
    end
end

@testset "macro" begin

@testset "bind new type" begin
    @test @allocated(mat(X)) == 0
    @test @allocated(mat(XGate{ComplexF32}())) > 0
    @const_gate X::ComplexF32
    @test @allocated(mat(XGate{ComplexF32}())) == 0
end

# @testset "define new" begin

#     A = rand(ComplexF64, 2, 2)
#     @eval @const_gate TEST = $A

#     @test_warn "TEST gate only accept complex typed matrix, your constant matrix has eltype: Float64" begin
#         @eval @const_gate TEST = rand(2, 2)
#     end

#     # NOTE: this defines a global vairable
#     @eval @const_gate TEST::ComplexF32 = rand(2, 2)

#     @test @allocated(TEST(ComplexF32)) == 0
# end

end
