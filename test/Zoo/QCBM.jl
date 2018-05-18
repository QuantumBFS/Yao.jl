using QuCircuit

include("kernel.jl")

function entangler(n)
    seq = []
    for i = 1:n
        push!(seq, X(i) |> C(i % n + 1))
    end
    compose(seq)(n)
end

function make_circuit(n, nlayer)
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

function run_circuit(circuit::AbstractBlock, params::Vector, signal::Int=3)
    psi = zero_state(nqubit(circuit))
    dispatch!(psi, params)
    vec(state(circuit(psi)))
end


"""
QCBM loss function.
    we can use
        samples = measure(psi, num_sample=20000)
    to get samples, here, we simply use the exact wave function.
"""
function loss_function(params::Vector{Float64}, circuit, kernel::Kernel, ptrain::Vector{Float64})
    prob = abs2.(run_circuit(circuit, params, 3))
    println(size(prob), size(ptrain), size(kernel.matrix))
    mmd_loss(prob, kernel, ptrain)
end

"""
QCBM gradient function.
"""
function mmd_gradient(params, circuit, kernel, ptrain)
    prob = abs2.(run_circuit(circuit, params, 3))

    grad = zeros(params)
    for i=1:length(params)
        params_ = copy(params)
        # pi/2 phase
        params_[i] += pi/2.
        prob_pos = abs2.(run_circuit(circuit, params_, 0))
        # -pi/2 phase
        params_[i] -= pi
        prob_neg = abs2.(run_circuit(circuit, params_, 0))

        grad_pos = expect(kernel, prob, prob_pos) - expect(kernel, prob, prob_neg)
        grad_neg = expect(kernel, ptrain, prob_pos) - expect(kernel, ptrain, prob_neg)
        grad[i] = grad_pos - grad_neg
    end
    return grad
end

