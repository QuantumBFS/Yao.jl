using Test
using Yao
using QuAlgorithmZoo

"""
    gaussian_pdf(x, μ::Real, σ::Real)

gaussian probability density function.
"""
function gaussian_pdf(x, μ::Real, σ::Real)
    pl = @. 1 / sqrt(2pi * σ^2) * exp(-(x - μ)^2 / (2 * σ^2))
    pl / sum(pl)
end

@testset "qcbm" begin
    # problem setup
    n = 6
    depth = 6

    N = 1<<n
    kernel = rbf_kernel(0:N-1, 0.25)
    pg = gaussian_pdf(1:N, N/2-0.5, N/4)
    circuit = random_diff_circuit(n, depth, pair_ring(n)) |> autodiff(:QC)
    dispatch!(circuit, :random)
    qcbm = QCBM(circuit, kernel, pg)

    # training
    niter = 100
    optim = Adam(lr=0.1)
    for info in QCBMGo!(qcbm, optim, niter) end
    @test qcbm |> loss < 1e-4
end
