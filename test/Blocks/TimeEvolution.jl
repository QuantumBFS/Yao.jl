using Test, LinearAlgebra, SparseArrays
using Yao
using Yao.Blocks
using Yao.Intrinsics

@testset "Time Evolution" begin
    hami = kron(3, 1=>X)
    te = TimeEvolution(hami, 0.2)

    @test applymatrix(te) ≈ mat(te)
    @test applymatrix(adjoint(te)) ≈ applymatrix(te)'

    # copy
    cte = copy(te)
    @test cte == te
    @test cte !== te
    hash1 = hash(cte)
    @test hash1 != hash(te)

    # dispatch
    dispatch!(cte, [2.0])
    @test cte != te
    @test cte.t == 2.0
    @test hash1 != hash(cte)
end
