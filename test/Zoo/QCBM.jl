using QuCircuit

include("mmd.jl")

function entangler(n)
    seq = []
    for i = 1:n
        push!(seq, X(i) |> C(i % n + 1))
    end
    compose(seq)(n)
end

function circuit(n, nlayer)
    first_layer = chain(rot(:X), rot(:Z)) |> cache(2, recursive=true) |> roll
    layer = chain(rot(:Z), rot(:X), rot(:Z)) |> cache(2, recursive=true) |> roll

    seq = []
    push!(seq, first_layer(n))
    for i = 1:nlayer
        push!(seq, cache(entangler(n)))
        push!(seq, layer(n))
    end
    chain(seq...)
end

import Base: run

function run_circuit(circuit::AbstractBlock, params::Vector, signal::Int=3)
    psi = zero_state(nqubit(circuit))
    dispatch!(psi, params)
    state(circuit(psi))
end


"""
QCBM loss function.
    we can use
        samples = measure(psi, num_sample=20000)
    to get samples, here, we simply use the exact wave function.
"""
function loss_function(params::Vector{Float64}, circuit, kernel::Kernel, ptrain::Vector{Float64})
    prob = abs2.(run_circuit(params, circuit, 3))
    println(size(prob), size(ptrain), size(kernel.kernel_matrix))
    prob |> mmd_loss(kernel, ptrain)
end

"""
QCBM gradient function.
"""
function mmd_gradient(params, circuit, kernel, ptrain)
    prob = run_circuit(params, circuit, 3) |> psi2prob

    grad = zeros(params)
    for i=1:length(params)
        params_ = copy(params)
        # pi/2 phase
        params_[i] += pi/2.
        prob_pos = abs2.(run_circuit(params_, circuit, 0))
        # -pi/2 phase
        params_[i] -= pi
        prob_neg = abs2.(run_circuit(params_, circuit, 0))

        grad_pos = kernel_expect(kernel, prob, prob_pos) - kernel_expect(kernel, prob, prob_neg)
        grad_neg = kernel_expect(kernel, ptrain, prob_pos) - kernel_expect(kernel, ptrain, prob_neg)
        grad[i] = grad_pos - grad_neg
    end
    return grad
end

