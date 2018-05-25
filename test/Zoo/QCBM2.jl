using QuCircuit

### Kernel

abstract type AbstractKernel end

struct RBFKernel <: AbstractKernel
    sigmas::Vector{Float64}
    matrix::Matrix{Float64}
end

function RBFKernel(nqubits::Int, sigmas::Vector{Float64}, isbinary::Bool)
    basis = collect(0:(1<<nqubits - 1))
    return RBFKernel(sigmas, rbf_kernel_matrix(basis, basis, sigmas, isbinary))
end

expect(kernel::RBFKernel, px::Vector{Float64}, py::Vector{Float64}) = px' * kernel.matrix * py

# RBF Kernel

function rbf_kernel_matrix(x::Vector, y::Vector, sigmas::Vector{Float64}, isbinary::Bool)
    if length(sigmas) == 0
        throw(DimensionMismatch("At least 1 sigma prameters is required for RBM kernel!"))
    end

    if isbinary
        dx2 = map(count_ones, xor.(x, y'))
    else
        dx2 = (x .- y').^2
    end

    K = 0
    for sigma in sigmas
        gamma = 1.0 / (2 * sigma)
        K = K + exp.(-gamma * dx2)
    end
    return K
end

function MMDLoss(px::AbstractVecOrMat{Float64}, kernel::RBFKernel, py::AbstractVecOrMat{Float64})
    pxy = px - py
    return expect(kernel, pxy, pxy)
end


## Circuit

function entangler(n, pairs)
    seq = []
    for (ctrl, u) in pairs
        push!(seq, X(u) |> C(ctrl))
    end
    compose(seq)(n)
end

function make_circuit(n, nlayers, pairs)

    first_layer = roll(n, chain(rot(:X), rot(:Z)))
    last_layer = roll(n, chain(rot(:Z), rot(:X)))
    # layer constructor
    # TODO: add cache after empty! is fixed
    layer = roll(chain(rot(:Z), rot(:X), rot(:Z)))

    layers = []
    push!(layers, first_layer)

    for i = 1:(nlayers - 1)
        push!(layers, cache(entangler(n, pairs)))
        push!(layers, layer(n))
    end

    push!(layers, cache(entangler(n, pairs)))
    push!(layers, last_layer)

    chain(layers...)
end

struct QCBM
    n::Int
    nlayers::Int
    circuit

    function QCBM(n, nlayers, pairs)
        new(n, nlayers, make_circuit(n, nlayers, pairs))
    end
end

nparameters(qcbm::QCBM) = 2 * 2 * qcbm.n + (qcbm.nlayers - 1) * 3 * qcbm.n

function (qcbm::QCBM)(params)
    psi = zero_state(nqubit(qcbm.circuit))
    dispatch!(qcbm.circuit, params)
    vec(state(qcbm.circuit(psi)))
end

function loss(qcbm::QCBM, params, kernel, ptrain)
    prob = abs2.(qcbm(params))
    MMDLoss(prob, kernel, ptrain)
end

import Base: gradient

function gradient(qcbm::QCBM, params, kernel, ptrain)
    tparams = copy(params)
    prob = abs2.(qcbm(tparams))

    grad = zeros(params)
    for i in eachindex(params)
        # pi/2 phase
        tparams = copy(params)
        tparams[i] += pi / 2
        prob_pos = abs2.(qcbm(tparams))

        tparams = copy(params)
        tparams[i] -= pi / 2
        prob_neg = abs2.(qcbm(tparams))

        grad_pos = expect(kernel, prob, prob_pos) - expect(kernel, prob, prob_neg)
        grad_neg = expect(kernel, ptrain, prob_pos) - expect(kernel, ptrain, prob_neg)
        grad[i] = grad_pos - grad_neg
    end
    return grad
end

function train(qcbm::QCBM, ptrain; learning_rate = 0.1, maxiter=10)
    params = 2pi * rand(nparameters(qcbm))
    kernel = RBFKernel(qcbm.n, [2.0], false)

    for i = 1:maxiter
        grad = gradient(qcbm, copy(params), kernel, ptrain)
        println(i, " step, loss = ", loss(qcbm, copy(params), kernel, ptrain))
        params .-= learning_rate * grad
    end

    params
end

function gaussian_pdf(n, μ, σ)
    x = collect(1:1<<n)
    pl = 1 / sqrt(2pi * σ^2) * exp.(-(x - μ)^2 / (2 * σ^2))
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

cnot_pair = [
    (2, 8),
    (3, 9),
    (5, 8),
    (6, 4),
    (7, 1),
    (7, 4),
    (7, 8),
    (9, 6),
];

qcbm = QCBM(9, 10, cnot_pair)
ptrain = normalize(rand(1 << 9))
train(qcbm, ptrain)
