using Yao
using Yao.Intrinsics
using QuAlgorithmZoo
using Test, LinearAlgebra
using OrdinaryDiffEq

function diffEq_problem(nbit::Int)
    siz = 1<<nbit
    A = (rand(ComplexF64, siz,siz))
    A = (A+A')/2
    b = normalize!(rand(ComplexF64, siz))
    x = normalize!(rand(ComplexF64, siz))
    A, b, x
end

@testset "Linear_differential_equation_Euler_HHL" begin
N = 1
h = 0.02
tspan = (0.0,0.6)
M, v, x = diffEq_problem(N)
A(t) = M
b(t) = v
res = solve_QuEuler(A, b, x, tspan, h)

f(u,p,t) = M*u + v;
prob = ODEProblem(f,x,tspan)
sol = solve(prob,Euler(),dt = 0.02,adaptive = :false)
s = vcat(sol.u...)
N_t = round(2*(tspan[2] - tspan[1])/h + 3);
r = res[Int((N_t+1)*2+2^N+1): Int((N_t+1)*2+2^N + N_t - 1)] # range of relevant values in the obtained state.
@test isapprox.(s,r,atol = 0.05) |> all
end
