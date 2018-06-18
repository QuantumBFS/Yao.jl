using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao.Registers
using Yao.Intrinsics

@testset "reorder" begin
    @test reorder(collect(0:7), [3,2,1]) == [0, 4, 2, 6, 1, 5, 3, 7]
    @test invorder(collect(0:7)) == [0, 4, 2, 6, 1, 5, 3, 7]

    A = randn(2, 2)
    B = randn(2, 2)
    C = randn(2, 2)
    ⊗ = kron
    @test reorder(C ⊗ B ⊗ A, [3,1,2]) ≈ B ⊗ A ⊗ C
    @test invorder(C ⊗ B ⊗ A) ≈ A ⊗ B ⊗ C


    v1, v2, v3 = randn(2), randn(2), randn(2)
    using Compat.Test
    @test repeat(register(v1 ⊗ v2 ⊗ v3), 2) |> invorder! ≈ repeat(register(v3 ⊗ v2 ⊗ v1), 2)

end
