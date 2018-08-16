using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao
using Yao.Blocks
using Yao.Intrinsics

@testset "Time Evolution" begin
    hami = kron(3, 1=>X)
    te = TimeEvolution(hami, 0.2)
    sp = sprand(4,4,0.5)

    @test applymatrix(te) ≈ mat(te)
    @test applymatrix(adjoint(te)) ≈ applymatrix(te)'

    # copy
    cte = copy(te)
    @test cte == te
    @test cte !== te
    hash1 = hash(cte)
    @test hash1 != hash(te)

    # dispatch
    dispatch!(cte, 2.0)
    @test cte != te
    @test cte.t == 2.0
    @test hash1 != hash(cte)
end
