using Test, YaoBlockTree

hm = kron(3, 1=>X)

@testset "test time evolution" begin
    te = TimeEvolution(hm, 0.2)
    @test applymatrix(adjoint(te)) ≈ applymatrix(te)'

    @test applymatrix(te) ≈ mat(te)
    @test isunitary(te)
    cte = copy(te)
    @test cte == te
end

@testset "test imaginary time evolution" begin
    tei = TimeEvolution(hm, 0.2; is_itime=true)
    @test applymatrix(tei) ≈ mat(tei)
    @test applymatrix(adjoint(tei)) ≈ applymatrix(tei)'
    @test !isunitary(tei)
end
