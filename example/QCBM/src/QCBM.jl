module QCBM

using Yao, UnicodePlots, Knet

include("Kernels.jl")
include("Circuit.jl")

function gaussian_pdf(n, μ, σ)
    x = collect(1:1<<n)
    pl = @. 1 / sqrt(2pi * σ^2) * exp(-(x - μ)^2 / (2 * σ^2))
    pl / sum(pl)
end

function get_nn_pairs(n)
    pairs = []
    for inth in 1:2
        for i in inth:2:n
            push!(pairs, (i, i % n + 1))
        end
    end
    pairs
end

function train!(qcbm::Model, ptrain, optim; learning_rate=0.1, maxiter=100)
    initialize!(qcbm)
    kernel = Kernels.RBFKernel(nqubits(qcbm), [0.25], false)
    history = Float64[]

    for i = 1:maxiter
        grad = gradient(qcbm, kernel, ptrain)
        curr_loss = loss(qcbm, kernel, ptrain)
        push!(history, curr_loss)
        println(i, " step, loss = ", curr_loss)

        params = parameters(qcbm)
        Knet.update!(params, grad, optim)
        dispatch!(qcbm, params)
    end
    history
end

function main(n, maxiter)
    pg = gaussian_pdf(n, 2^5-0.5, 2^4)
    fig = lineplot(0:1<<n - 1, pg)
    display(fig)

    qcbm = Model{n, 10}(get_nn_pairs(n))
    optim = Adam(lr=0.1)
    his = train!(qcbm, pg, optim, maxiter=maxiter)

    display(lineplot(his, title = "loss"))
    psi = qcbm()
    p = abs2.(statevec(psi))
    p = p / sum(p)
    lineplot!(fig, p, color=:yellow, name="trained")
    display(fig)
end

end

QCBM.main(6, 20)
