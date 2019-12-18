using YaoExtensions, Yao
using Test, Random
using Optim: LBFGS, optimize
using Optim

"""
    learn_u4(u::AbstractMatrix; niter=100)

Learn a general U4 gate. The optimizer is LBFGS.
"""
function learn_u4(u::AbstractBlock; niter=100)
    ansatz = general_U4()
    params = parameters(ansatz)
    println("initial loss = $(operator_fidelity(u,ansatz))")
    optimize(x->-operator_fidelity(u, dispatch!(ansatz, x)),
            (G, x) -> (G .= -operator_fidelity'(u, dispatch!(ansatz, x))[2]),
            parameters(ansatz),
            LBFGS(),
            Optim.Options(iterations=niter))
    println("final fidelity = $(operator_fidelity(u,ansatz))")
    return ansatz
end

using Random
Random.seed!(2)
u = matblock(rand_unitary(4))
c = learn_u4(u; niter=150)
