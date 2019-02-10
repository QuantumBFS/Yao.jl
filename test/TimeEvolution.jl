using Test, LinearAlgebra, SparseArrays
using YaoBase, YaoBlockTree

@testset "Time Evolution" begin
    hami = kron(3, 1=>X)
    te = TimeEvolution(hami, 0.2)

    @test applymatrix(te) ≈ mat(te)
    @test applymatrix(adjoint(te)) ≈ applymatrix(te)'
    @test isunitary(te)

    tei = TimeEvolution(hami, 0.2im)
    @test applymatrix(tei) ≈ mat(tei)
    @test applymatrix(adjoint(tei)) ≈ applymatrix(tei)'
    @test !isunitary(tei)

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
    @test setiparameters!(cte, 0.5).t == 0.5
    @test setiparameters!(cte, :random).t != 0.5
    @test setiparameters!(cte, :zero).t == 0.0
end
