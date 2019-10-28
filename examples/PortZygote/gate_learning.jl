using YaoExtensions, Yao
using Test, Random
using QuAlgorithmZoo: Adam, update!

include("zygote_patch.jl")

function loss(u, ansatz)
    m = Matrix(ansatz)
    sum(abs.(u .- m))
end

function learn_su4(u::AbstractMatrix; optimizer=Adam(lr=0.1), niter=100)
    ansatz = general_U4() * put(2, 1=>phase(0.0))  # initial values are 0, here, we attach a global phase.
    params = parameters(ansatz)
    for i=1:1000
        println("Step = $i, loss = $(loss(u,ansatz))")
        grad = gradient(ansatz->loss(u, ansatz), ansatz)[1]
        update!(params, grad, optimizer)
        dispatch!(ansatz, params)
    end
    return ansatz
end

using Random
Random.seed!(2)
u = rand_unitary(4)
using LinearAlgebra
#u[:,1] .*= -conj(det(u))
#@show det(u)
c = learn_su4(u; optimizer=Adam(lr=0.005))
det(mat(c))
