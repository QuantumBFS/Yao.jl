using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays
using Yao
using Yao.Blocks

@testset "builtins" begin
    for each in [X, Y, Z, H]
        @test nqubits(each) == 1
        @test ninput(each) == 1
        @test noutput(each) == 1
        @test isunitary(each) == true
        @test isreflexive(each) == true
        @test ispure(each) == true
        @test ishermitian(each) == true

        # new constant gate is the same
        # no copy occurred
        @test X() === X
    end


    @testset "matrix" begin
        for (each, MAT) in [
            (X, [0 1;1 0]),
            (Y, [0 -im; im 0]),
            (Z, [1 0;0 -1]),
            (H, (elem = 1 / sqrt(2); [elem elem; elem -elem])),
        ]

            @test mat(each) ≈ MAT

        end
    end
end

@testset "macro" begin

@testset "bind new type" begin
    @test @allocated(mat(X)) == 0
    @test @allocated(mat(X(ComplexF32))) > 0
    @const_gate X::ComplexF32
    @test @allocated(mat(X(ComplexF32))) == 0
end

@testset "define new" begin

    A = rand(ComplexF64, 2, 2)
    @eval @const_gate TEST = $A

    @test_warn "TEST gate only accept complex typed matrix, your constant matrix has eltype: Float64" begin
        @eval @const_gate TEST = rand(2, 2)
    end

    # NOTE: this defines a global vairable
    @eval @const_gate TEST::ComplexF32 = rand(2, 2)

    @test @allocated(TEST(ComplexF32)) == 0
end

end
