# # Quantum GAN
using Yao, YaoExtensions
using Yao.ConstGate: P0
import QuAlgorithmZoo
using Test, Random

include("QuGANlib.jl")

# ## DATA: Target Wave Function
# here we learn a 3 qubit state
nbit = 3
target_state = rand_state(nbit)

# ## MODEL: Quantum Circuit and Loss
# using a 4-layer random differential circuit for both generator and discriminator
# we build the qcgan setup.
depth_gen = 4
generator = dispatch!(variational_circuit(nbit, depth_gen, pair_ring(nbit)), :random) |> autodiff(:QC);

#------------------------------
depth_disc = 4
discriminator = dispatch!(variational_circuit(nbit+1, depth_disc, pair_ring(nbit+1)), :random) |> autodiff(:QC)
qg = QuGAN(target_state, generator, discriminator);

# ## TRAINING: Gradient Descent
# using a proper learning parameters, we perform 1000 steps of training
g_learning_rate=0.2
d_learning_rate=0.5
niter=1000
for info in QuGANGo!(qg, g_learning_rate, d_learning_rate, niter)
    i = info["step"]
    (i*20)%niter==0 && println("Step = $i, Trace Distance = $(tracedist(qg)), loss = $(qg |> loss)")
end
