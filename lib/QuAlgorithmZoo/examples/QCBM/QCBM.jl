# # Quantum Circuit Born Machine
using Yao, YaoExtensions
import Yao: probs
using QuAlgorithmZoo: Adam, update!

struct QCBM{BT<:AbstractBlock, MT<:MMD}
    circuit::BT
    mmd::MT
end

"""generated output probability distribution"""
function probs(qcbm::QCBM)
    zero_state(qcbm.circuit |> nqubits) |> qcbm.circuit |> probs
end

function loss(qcbm::QCBM)
    expect(qcbm.mmd, probs(qcbm) |> as_weights)
end

function getgrad(qcbm::QCBM)
    expect'(qcbm.mmd, zero_state(nqubits(qcbm.circuit))=>qcbm.circuit).second
end

# ## DATA: Target Probability Distribution
# The gaussian probability disctribution in phase space of 2^6
nbit = 6
N = 1<<nbit

function gaussian_pdf(x, μ::Real, σ::Real)
    pl = @. 1 / sqrt(2pi * σ^2) * exp(-(x - μ)^2 / (2 * σ^2))
    pl / sum(pl)
end
pg = gaussian_pdf(1:N, N/2-0.5, N/4);

# ## MODEL: Quantum Circuit and Loss
# Using a random differentiable circuit of depth 6 for training, the kernel function is universal RBF kernel
depth = 6
kernel = rbf_kernel(0.25)
c = variational_circuit(nbit, depth, pair_ring(nbit))
dispatch!(c, :random)
qcbm = QCBM(c, MMD(kernel, pg))

# ## TRAINING: Adam Optimizer
# We probide the QCBMGo! iterative interface for training
niter = 100
optim = Adam(lr=0.1)

params = parameters(qcbm.circuit)
for i=1:niter
    # initialize the parameters
    update!(params, getgrad(qcbm), optim)
    dispatch!(qcbm.circuit, params)
    println("Step = $i, Loss = $(loss(qcbm))")
end
