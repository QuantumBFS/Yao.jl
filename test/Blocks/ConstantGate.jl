using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays
using Yao
using Yao.Blocks
using Yao.LuxurySparse
using Yao.Intrinsics

CNOT_R = PermMatrix([1, 2, 4, 3], ones(ComplexF64, 4))
Toffoli_R = PermMatrix([1, 2, 3, 4, 5, 6, 8, 7], ones(ComplexF64, 8))

@testset "builtins" begin
    for each in [X, Y, Z, H]
        @test nqubits(each) == 1
        @test isunitary(each) == true
        @test isreflexive(each) == true
        @test ishermitian(each) == true
    end
    @test nqubits(CNOT) == 2
    @test isunitary(CNOT) == true
    @test isreflexive(CNOT) == true
    @test ishermitian(CNOT) == true
    @test nqubits(Toffoli) == 3
    @test isunitary(Toffoli) == true
    @test isreflexive(Toffoli) == true
    @test ishermitian(Toffoli) == true


    @testset "matrix" begin
        for (each, MAT) in [
            (X, [0 1;1 0]),
            (Y, [0 -im; im 0]),
            (Z, [1 0;0 -1]),
            (H, (elem = 1 / sqrt(2); [elem elem; elem -elem])),
        ]

            @test mat(each) ≈ MAT

        end
        mat(CNOT) |> reorder |> CNOT_R
        mat(Toffoli) |> reorder |> Toffoli_R
    end
end

@testset "macro" begin

@testset "bind new type" begin
    @test @allocated(mat(X)) == 0
    @test @allocated(mat(X(ComplexF32))) > 0
    @const_gate X::ComplexF32
    @test @allocated(mat(X(ComplexF32))) == 0
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
