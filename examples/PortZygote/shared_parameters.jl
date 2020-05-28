include("zygote_patch.jl")

import YaoExtensions, Random

c = YaoExtensions.variational_circuit(5)
h = YaoExtensions.heisenberg(5)

function loss(h, c, θ) where N
    # the assign is nessesary!
    c = dispatch!(c, fill(θ, nparameters(c)))
    reg = apply!(zero_state(nqubits(c)), c)
    real(expect(h, reg))
end

reg0 = zero_state(5)
zygote_grad = Zygote.gradient(θ->loss(h, c, θ), 0.5)[1]


# check gradients
using Test
dispatch!(c, fill(0.5, nparameters(c)))
greg, gparams = expect'(h, zero_state(5)=>c)
true_grad = sum(gparams)

@test true_grad ≈ true_grad
