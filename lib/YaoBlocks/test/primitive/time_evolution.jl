using Test, YaoBlocks, YaoArrayRegister
using YaoBlocks: BlockMap
using LinearAlgebra

function myheisenberg(n::Int; periodic::Bool = true)
    Sx(i) = put(n, i => X)
    Sy(i) = put(n, i => Y)
    Sz(i) = put(n, i => Z)

    res = map(1:(periodic ? n : n - 1)) do i
        j = mod1(i, n)
        Sx(i) * Sx(j) + Sy(i) * Sy(j) + Sz(i) * Sz(j)
    end
    Add(res)
end

@testset "constructor:time evolution" begin
    hm = myheisenberg(4)
    te = TimeEvolution(hm, 0.2)
    # copy
    cte = copy(te)
    @test cte == te
    @test cte !== te

    # dispatch
    dispatch!(cte, [2.0])
    @test cte != te
    @test cte.dt == 2.0
    @test setiparams!(cte, 0.5).dt == 0.5
    @test setiparams!(cte, :random).dt != 0.5
    @test setiparams!(cte, :zero).dt == 0.0
    @test setiparams(cte, 0.5).dt == 0.5
    @test setiparams(cte, :random).dt != 0.5
    @test setiparams(cte, :zero).dt == 0.0
end

@testset "test imaginary time evolution" begin
    hm = myheisenberg(4)
    tei = TimeEvolution(hm, 0.2im)
    r = rand_state(4)
    r1 = copy(r) |> tei
    @test exp(Matrix(mat(hm)) * 0.2) * r.state ≈ r1.state

    @test applymatrix(tei) ≈ mat(tei)
    @test applymatrix(adjoint(tei)) ≈ applymatrix(tei)'
    @test !isunitary(tei)
    @test !isunitary(tei |> mat)

    # diagonal time evolution
    hm = matblock(Diagonal(randn(1<<4)))
    tei = TimeEvolution(hm, 0.2im)
    r = rand_state(4)
    r1 = copy(r) |> tei
    @test exp(Matrix(mat(hm)) * 0.2) * r.state ≈ r1.state

    @test applymatrix(tei) ≈ mat(tei)
    @test applymatrix(adjoint(tei)) ≈ applymatrix(tei)'
    @test !isunitary(tei)
    @test !isunitary(tei |> mat)
end

@testset "test time evolution" begin
    hm = myheisenberg(4)
    te = TimeEvolution(hm, 0.2)

    r = rand_state(4)
    r1 = copy(r) |> te
    @test exp(Matrix(mat(hm)) * -0.2im) * r.state ≈ r1.state
    @test applymatrix(adjoint(te)) ≈ applymatrix(te)'

    @test applymatrix(te) ≈ mat(te)
    @test isunitary(te)
    @test isunitary(te |> mat)
    cte = copy(te)
    @test cte == te

    # diagonal
    te = TimeEvolution(kron(Z, Z), 0.5)
    @test applymatrix(te) ≈ mat(te)
    @test mat(te) isa Diagonal

    @test !isdiagonal(time_evolve(X, 0.5))
    @test isdiagonal(time_evolve(Z, 0.5))
end

@testset "block map" begin
    @test BlockMap(ComplexF64, X) isa BlockMap{ComplexF64,typeof(X)}

    @test BlockMap(ComplexF64, X).block === X

    st = rand(ComplexF64, 2)
    @test BlockMap(ComplexF64, X) * st ≈ mat(X) * st
    @test ishermitian(BlockMap(ComplexF64, X))
    @test size(BlockMap(ComplexF64, X)) == (2, 2)
end

@testset "qudits" begin
    reg = zero_state(1; nlevel=3)
    H = randn(ComplexF64, 3,3)
    reg2 = apply(reg, time_evolve(matblock(H + H'; nlevel=3), 0.5))
    @test nlevel(reg2) == 3
    @test isnormalized(reg2)
end

@testset "instruct_get_element" begin
    for pb in [time_evolve(put(3, 2=>Y), 0.5), time_evolve(cache(put(3, (3,1)=>matblock(rand_hermitian(9); nlevel=3))), 0.5)
            ]
        mpb = mat(pb)
        allpass = true
        for i=basis(pb), j=basis(pb)
            allpass &= isapprox(pb[i, j], mpb[Int(i)+1, Int(j)+1]; atol=1e-6)
            allpass &= isapprox(pb[i, j], mpb[Int(i)+1, Int(j)+1]; atol=1e-6, rtol=1e-6)
        end
        @test allpass

        allpass = true
        for j=basis(pb)
            allpass &= isapprox(vec(pb[:, j]), mpb[:, Int(j)+1]; atol=1e-6)
            allpass &= isapprox(vec(pb[j,:]), mpb[Int(j)+1,:]; atol=1e-6)
            allpass &= isapprox(vec(pb[:, EntryTable([j], [1.0+0im])]), mpb[:, Int(j)+1]; atol=1e-6)
            allpass &= isapprox(vec(pb[EntryTable([j], [1.0+0im]),:]), mpb[Int(j)+1,:]; atol=1e-6)
            allpass &= isapprox(vec(pb[:, j]), mpb[:, Int(j)+1]; atol=1e-6, rtol=1e-6)
            allpass &= isapprox(vec(pb[j,:]), mpb[Int(j)+1,:]; atol=1e-6, rtol=1e-6)
            allpass &= isapprox(vec(pb[:, EntryTable([j], [1.0+0im])]), mpb[:, Int(j)+1]; atol=1e-6, rtol=1e-6)
            allpass &= isapprox(vec(pb[EntryTable([j], [1.0+0im]),:]), mpb[Int(j)+1,:]; atol=1e-6, rtol=1e-6)
            allpass &= isclean(pb[:,j])
        end
        @test allpass
    end
end
