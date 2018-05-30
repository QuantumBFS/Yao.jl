include("Kernel.jl")
import .Kernels
using Yao, Lazy

function entangler(pairs)
    seq = []
    for (ctrl, u) in pairs
        push!(seq, X(u) |> C(ctrl))
    end
    compose(seq)
end

layer(x::Symbol) = layer(Val{x})
layer(::Type{Val{:first}}) = roll(chain(Rx(), Rz()))
layer(::Type{Val{:last}}) = roll(chain(Rz(), Rx()))
layer(::Type{Val{:mid}}) = roll(chain(Rz(), Rx(), Rz()))

struct QCBM{N, NL, CT, T} <: Yao.CompositeBlock{N, T}
    circuit::CT

    function QCBM{N, NL}(pairs) where {N, NL}
        layers = []
        push!(layers, layer(:first))

        for i = 1:(NL - 1)
            push!(layers, cache(entangler(pairs)))
            push!(layers, layer(:mid))
        end

        push!(layers, cache(entangler(pairs)))
        push!(layers, layer(:last))
        circuit = N |> compose(layers)
        new{N, NL, typeof(circuit), datatype(circuit)}(circuit)
    end
end

function (x::QCBM{N})(nbatch::Int=1) where N
    x.circuit(zero_state(N, nbatch))
end

Yao.dispatch!(f::Function, qcbm::QCBM, params...) = (dispatch!(f, qcbm.circuit, params...); qcbm)
Yao.dispatch!(f::Function, qcbm::QCBM, params::Vector) = (dispatch!(f, qcbm.circuit, params); qcbm)

function initialize!(qcbm::QCBM)
    params = 2pi * rand(nparameters(qcbm))
    dispatch!(qcbm, params)
end

(x::QCBM)(params...) = x.circuit(params...)
@forward QCBM.circuit Yao.mat, Yao.apply!, Yao.show, Yao.nparameters, Yao.blocks

function parameters(qcbm::QCBM{N, NL}) where {N, NL}
    params = zeros(real(datatype(qcbm)), nparameters(qcbm))
    idx = 0
    for ilayer = 1:2:(2 * NL + 1)
        idx = parameters!(params, idx, qcbm.circuit[ilayer])
    end
    params
end

# TODO: remove this by a new primitive block
function parameters!(params, idx, layer::Yao.Roller)
    count = idx
    for each_line in layer
        for each in each_line
            params[count + 1] = each.theta
            count += 1
        end
    end
    count
end

import Base: gradient

function gradient(qcbm::QCBM{N, NL}, kernel, ptrain) where {N, NL}
    prob = abs2.(statevec(qcbm()))
    grad = zeros(real(datatype(qcbm)), nparameters(qcbm))
    idx = 0
    for ilayer = 1:2:(2 * NL + 1)
        idx = grad_layer!(grad, idx, prob, qcbm, qcbm.circuit[ilayer], kernel, ptrain)
    end
    grad
end

function grad_layer!(grad, idx, prob, qcbm, layer, kernel, ptrain)
    count = idx
    for each_line in layer
        for each in each_line
            gradient!(grad, count + 1, prob, qcbm, each, kernel, ptrain)
            count += 1
        end
    end
    count
end

function gradient!(grad, idx, prob, qcbm, gate, kernel, ptrain)
    dispatch!(+, gate, pi / 2)
    prob_pos = abs2.(statevec(qcbm()))

    dispatch!(-, gate, pi)
    prob_neg = abs2.(statevec(qcbm()))

    dispatch!(+, gate, pi / 2) # set back

    grad_pos = Kernels.expect(kernel, prob, prob_pos) - Kernels.expect(kernel, prob, prob_neg)
    grad_neg = Kernels.expect(kernel, ptrain, prob_pos) - Kernels.expect(kernel, ptrain, prob_neg)
    grad[idx] = grad_pos - grad_neg
    grad
end

loss(qcbm::QCBM, kernel, ptrain) = Kernels.loss(abs2.(statevec(qcbm())), kernel, ptrain)
