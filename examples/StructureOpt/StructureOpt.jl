using Yao, YaoExtensions
using YaoBlocks.Optimise: replace_block
using YaoBlocks.ConstGate
using YaoBlocks
using Test
using LinearAlgebra

"""
    TODO:
    * optimize to optimal value,
    * if this optimal value's loss is close to `θ = 0.0`, kill it.
"""
performance(params, gradient) = abs.(params .* gradient)

nbit = 5
c = variational_circuit(nbit, 50)

dispatch!(c, :random)
h = heisenberg(nbit)
cc = replace_block(x->x isa RotationGate ? Bag(x) : x, c)

function train(h, c; kill_rate=0.1, kill_step=10, niter=100)
    bags = blockfilter(b->b isa Bag && isenabled(b), c)
    for i=1:niter
        regδ, paramsδ = expect'(h, zero_state(nbit) => c)
        dispatch!(-, c, 0.01 .* paramsδ)
        loss = expect(h, zero_state(nbit)=>c) |> real

        Nk = round(Int, kill_rate*length(paramsδ))

        if i%kill_step == 0 && kill_rate != 0
            ps = performance(parameters(c), paramsδ)
            cut = sort(ps)[Nk]
            disable_block!.(bags[ps .<= cut])
            bags = bags[ps .> cut]
        end
        @show i,nparameters(c), loss
    end
end


train(h, cc; kill_rate=0.01, niter=200)

cr = variational_circuit(nbit, 5)
dispatch!(cr, :random)
train(h, cr; kill_rate=0.0, niter=200)
