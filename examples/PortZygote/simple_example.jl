using Zygote
include("chainrules_patch.jl")

import YaoExtensions, Random

c = YaoExtensions.variational_circuit(5)
dispatch!(c, :random)

function loss(reg::AbstractRegister, circuit::AbstractBlock{N}) where N
    #copy(reg) |> circuit
    reg = apply!(copy(reg), circuit)
    st = state(reg)
    sum(real(st.*st))
end

reg0 = zero_state(5)
paramsδ = gradient(c->loss(reg0, c), c)[1]
regδ = gradient(reg->loss(reg, c), reg0)[1]
