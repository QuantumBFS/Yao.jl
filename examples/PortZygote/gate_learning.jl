using YaoExtensions, Yao
using Test, Random
using Optim: LBFGS, optimize
using Optim

# port the `Matrix` function to Yao's AD.
using Zygote
include("chainrules_patch.jl")

function loss(u, ansatz)
    m = Matrix(ansatz)
    sum(abs.(u .- m))
end

"""
    learn_u4(u::AbstractMatrix; niter=100)

Learn a general U4 gate. The optimizer is LBFGS.
"""
function learn_u4(u::AbstractMatrix; niter=100)
    ansatz = general_U4() * put(2, 1=>phase(0.0))  # initial values are 0, here, we attach a global phase.
    params = parameters(ansatz)
    g!(G, x) = (dispatch!(ansatz, x); G .= Zygote.gradient(ansatz->loss(u, ansatz), ansatz)[1])
    optimize(x->(dispatch!(ansatz, x); loss(u, ansatz)), g!, parameters(ansatz),
                    LBFGS(), Optim.Options(iterations=niter))
    println("final loss = $(loss(u,ansatz))")
    return ansatz
end

using Random
Random.seed!(3)
u = rand_unitary(4)
c = learn_u4(u; niter=150)
