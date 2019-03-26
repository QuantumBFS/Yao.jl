using Yao
using Yao.Intrinsics
using QuAlgorithmZoo
using Test, LinearAlgebra
using OrdinaryDiffEq

function diffeq_problem(nbit::Int)
    siz = 1<<nbit
    A = (rand(ComplexF64, siz,siz))
    A = (A + A')/2
    b = normalize!(rand(ComplexF64, siz))
    x = normalize!(rand(ComplexF64, siz))
    A, b, x
end

@testset "Linear_differential_equations_HHL" begin
    N = 1
    h = 0.1
    tspan = (0.0,0.6)
    N_t = round(Int, 2*(tspan[2] - tspan[1])/h + 3)
    M, v, x = diffeq_problem(N)
    A(t) = M
    b(t) = v
    n_reg = 12
    f(u,p,t) = M*u + v;
    prob = ODEProblem(f, x, tspan)
    qprob = QuLDEMSProblem(A, b, x, tspan)
    sol = solve(prob, Tsit5(), dt = h, adaptive = :false)
    s = vcat(sol.u...)

    res = solve(qprob, QuEuler(), h, n_reg)
    r = res[(N_t + 1)*2 + 2^N - 1: (N_t + 1)*2 + 2^N + N_t - 3] # range of relevant values in the obtained state.
    @test isapprox.(s, r, atol = 0.5) |> all

    res = solve(qprob, QuLeapfrog(), h, n_reg)
    r = res[(N_t + 1)*2 + 2^N - 1: (N_t + 1)*2 + 2^N + N_t - 3] # range of relevant values in the obtained state.
    @test isapprox.(s, r, atol = 0.3) |> all

    res = solve(qprob, QuAB2(), h,n_reg)
    r = res[(N_t + 1)*2 + 2^N - 1: (N_t + 1)*2 + 2^N + N_t - 3] # range of relevant values in the obtained state.
    @test isapprox.(s, r, atol = 0.3) |> all

    res = solve(qprob, QuAB3(), h,n_reg)
    r = res[(N_t + 1)*2 + 2^N - 1: (N_t + 1)*2 + 2^N + N_t - 3] # range of relevant values in the obtained state.
    @test isapprox.(s, r, atol = 0.3) |> all

    res = solve(qprob, QuAB4(), h ,n_reg)
    r = res[(N_t + 1)*2 + 2^N - 1: (N_t + 1)*2 + 2^N + N_t - 3] # range of relevant values in the obtained state.
    @test isapprox.(s, r, atol = 0.3) |> all
end;
