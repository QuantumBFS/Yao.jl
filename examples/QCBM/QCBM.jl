# # Quantum Circuit Born Machine

using Yao, YaoExtensions
import QuAlgorithmZoo
include("qcbmlib.jl")

# ## DATA: Target Probability Distribution
# The gaussian probability disctribution in phase space of 2^6
nbit = 6
N = 1<<nbit
pg = gaussian_pdf(1:N, N/2-0.5, N/4);

# ## MODEL: Quantum Circuit and Loss
# Using a random differentiable circuit of depth 6 for training, the kernel function is universal RBF kernel
depth = 6
kernel = rbf_kernel(0:N-1, 0.25)
c = variational_circuit(nbit, depth, pair_ring(nbit)) |> autodiff(:QC);
dispatch!(c, :random)
qcbm = QCBM(c, kernel, pg);

# ## TRAINING: Adam Optimizer
# We probide the QCBMGo! iterative interface for training
niter = 100
optim = Adam(lr=0.1)
for info in QCBMGo!(qcbm, optim, niter)
    curr_loss = loss(qcbm, info["probs"])
    println("Step = ", info["step"], ", Loss = ", curr_loss)
end
