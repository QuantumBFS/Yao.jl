using Zygote
include("chainrules_patch.jl")

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

@test zygote_grad ≈ true_grad

# the batched version
function loss2(h, c, θ) where N
    # the assign is nessesary!
    c = dispatch!(c, fill(θ, nparameters(c)))
    reg = zero_state(nqubits(c),nbatch=2)
    reg = apply!(reg, c)
    sum(real(expect(h, reg)))
end

reg0 = zero_state(5)
zygote_grad2 = Zygote.gradient(θ->loss2(h, c, θ), 0.5)[1]
true_grad2 = (loss2(h, c, 0.5+1e-5) - loss2(h, c, 0.5-1e-5)) / 2e-5
@test true_grad2 ≈ zygote_grad2