using Test
using Yao
using QuAlgorithmZoo
using Random

function run_test(nbit::Int, depth_gen::Int, depth_disc::Int; g_lr=0.1, d_lr=0.2, niter=1000)
    qg = toy_qugan(rand_state(nbit), depth_gen, depth_disc)
    for info in QuGANGo!(qg, g_lr, d_lr, niter) end
    qg
end

# to fix
@testset "quantum circuit gan - opdiff" begin
    Random.seed!(2)
    N = 3
    target = rand_state(N)
    qcg = toy_qugan(target, 2, 2)
    grad = gradient(qcg)
    @test isapprox(grad, num_gradient(qcg), atol=1e-4)
    qg = run_test(3, 4, 4, g_lr=0.2, d_lr=0.5, niter=300)
    @test qg |> loss < 0.1
    qg = run_test(3, 4, 4, g_lr=Adam(lr=0.005), d_lr=Adam(lr=0.5), niter=1000)
    @test qg |> loss < 0.1
end
