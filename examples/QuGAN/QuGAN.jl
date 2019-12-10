using Yao
using YaoExtensions: variational_circuit, Sequence, faithful_grad, numdiff
using QuAlgorithmZoo: Adam, update!
import Yao: tracedist

"""
Quantum GAN.

Reference:
    Benedetti, M., Grant, E., Wossnig, L., & Severini, S. (2018). Adversarial quantum circuit learning for pure state approximation, 1–14.
"""
struct QuGAN{N}
    target::ArrayReg
    generator::AbstractBlock{N}
    discriminator::AbstractBlock
    reg0::ArrayReg
    witness_op::AbstractBlock
    circuit::AbstractBlock

    function QuGAN(target::ArrayReg, gen::AbstractBlock, dis::AbstractBlock)
        N = nqubits(target)
        c = Sequence([gen, addbits!(1), dis])
        witness_op = put(N+1, (N+1)=>ConstGate.P0)
        new{N}(target, gen, dis, zero_state(N), witness_op, c)
    end
end

# INTERFACES
circuit(qg::QuGAN) = qg.circuit
loss(qg::QuGAN) = p0t(qg) - p0g(qg)

function gradient(qg::QuGAN)
    grad_gen = faithful_grad(qg.witness_op, qg.reg0 => qg.circuit)
    grad_tar = faithful_grad(qg.witness_op, qg.target => qg.circuit[2:end])
    ngen = nparameters(qg.generator)
    [-grad_gen[1:ngen]; grad_tar - grad_gen[ngen+1:end]]
end

"""probability to get evidense qubit 0 on generation set."""
p0g(qg::QuGAN) = expect(qg.witness_op, qg.reg0 => qg.circuit) |> real
"""probability to get evidense qubit 0 on target set."""
p0t(qg::QuGAN) = expect(qg.witness_op, qg.target => qg.circuit[2:end]) |> real
"""generated wave function"""
outputψ(qg::QuGAN) = copy(qg.reg0) |> qg.generator

"""tracedistance between target and generated wave function"""
tracedist(qg::QuGAN) = tracedist(qg.target, outputψ(qg))[]

using Test, Random
Random.seed!(2)

nbit = 3
depth_gen = 4
depth_dis = 4

# define a QuGAN
target = rand_state(nbit)
generator = dispatch!(variational_circuit(nbit, depth_gen), :random)
discriminator = dispatch!(variational_circuit(nbit+1, depth_dis), :random)
qg = QuGAN(target, generator, discriminator)

# check the gradient
grad = gradient(qg)
numgrad = numdiff(c->loss(qg), qg.circuit)
@test isapprox(grad, numgrad, atol=1e-4)

# learning rates for the generator and discriminator
g_lr = 0.2
d_lr = 0.5
for i=1:300
    ng = nparameters(qg.generator)
    grad = gradient(qg)
    dispatch!(-, qg.generator, grad[1:ng]*g_lr)
    dispatch!(-, qg.discriminator, -grad[ng+1:end]*d_lr)
    println("Step $i, trace distance = $(tracedist(qg))")
end

@test qg |> loss < 0.1
