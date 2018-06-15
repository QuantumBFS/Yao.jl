using Yao
using Yao.Blocks
import Yao.Blocks: mat, apply!, blocks, dispatch!

# some factories
entangler(pairs) = chain(control([ctrl, ], u=>X) for (ctrl, u) in pairs)
layer(x::Symbol) = layer(Val(x))
layer(::Val{:first}) = rollrepeat(chain(Rx(), Rz()))
layer(::Val{:last}) = rollrepeat(chain(Rz(), Rx()))
layer(::Val{:mid}) = rollrepeat(chain(Rz(), Rx(), Rz()))

struct Model{N, NL, CT, T} <: CompositeBlock{N, T}
    circuit::CT

    function Model{N, NL}(pairs) where {N, NL}
        circuit = chain(N)
        push!(circuit, layer(:first))

        for i = 1:(NL - 1)
            push!(circuit, cache(entangler(pairs)))
            push!(circuit, layer(:mid))
        end

        push!(circuit, cache(entangler(pairs)))
        push!(circuit, layer(:last))
        new{N, NL, typeof(circuit), datatype(circuit)}(circuit)
    end
end

mat(x::Model) = mat(x.circuit)
apply!(r::AbstractRegister, x::Model, params...) = apply!(r, x.circuit, params...)
blocks(x::Model) = blocks(x.circuit)
dispatch!(x::Model, params...) = dispatch!(x.circuit, params...)
dispatch!(f::Function, x::Model, params...) = dispatch!(f, x.circuit, params...)

function (x::Model{N})(nbatch::Int=1) where N
    with!(x.circuit, zero_state(N, nbatch))
end

import Base: gradient

function initialize!(qcbm::Model)
    params = 2pi * rand(nparameters(qcbm))
    dispatch!(qcbm, params)
end

function gradient(qcbm::Model{N, NL}, kernel, ptrain) where {N, NL}
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
    for each_line in blocks(layer)
        for each in blocks(each_line)
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

loss(qcbm::Model, kernel, ptrain) = Kernels.loss(abs2.(statevec(qcbm())), kernel, ptrain)

qcbm = Model{4, 3}(i=>i+1 for i=1:3)
initialize!(qcbm)
parameters(qcbm)
