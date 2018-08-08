using Test, Random, LinearAlgebra, SparseArrays

using Yao
using Yao.Blocks

import Yao.Blocks: GeneralMatrixGate

@testset "MatrixGate" begin
    mg = GeneralMatrixGate(randn(4,4))
    mg2 = copy(mg)
    @test mg2 == mg
    mg2.matrix[:, 2] .= 10
    @test mg2 != mg
    @test nqubits(mg) == 2
    @test_throws DimensionMismatch GeneralMatrixGate(randn(3,3))

    reg = rand_state(2)
    @test copy(reg) |> mg |> statevec == mg.matrix * reg.state |> vec
end
