using Test, Random, LinearAlgebra, SparseArrays

using Yao
using Yao.Registers
using Yao.Intrinsics

@testset "⊗" begin
    #test for kron
    A = randn(6, 6)
    B = randn(6, 6)
    @test kron(A, B) == A ⊗ B

    reg1 = rand_state(6)
    reg2 = rand_state(6)
    @test join(reg1, reg2) == reg1 ⊗ reg2
end

@testset "|>" begin
    # test for pip
    reg1 = rand_state(6)
    g = put(6, (2,3)=>CNOT)
    @test apply!(copy(reg1), g) == reg1 |> copy |> g
end
