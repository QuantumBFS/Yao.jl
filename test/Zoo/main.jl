using Compat.Test
include("QCBM.jl")

const nlayers = 10
const nbit = 9
const maxiter = 10
const learning_rate = 0.1

const kernel = RBFKernel(nbit, [2.0], false)
const params = reverse(vec(readdlm("theta-cl-bs.dat")))
const target = readdlm("wave_complex.dat")[:, 1] + im * readdlm("wave_complex.dat")[:, 2]
const ptrain = rand(1 << 9)

cnot_pair = [
    (2, 8),
    (3, 9),
    (5, 8),
    (6, 4),
    (7, 1),
    (7, 4),
    (7, 8),
    (9, 6),
]

function entangler(n, pairs)
    seq = []
    for (c, uc) in pairs
        push!(seq, X(uc) |> C(c))
    end
    compose(seq)(n)
end


layer1 = roll(nbit, chain(rot(:X), rot(:Z)))
layers = MatrixBlock[]
push!(layers, layer1)
layer = roll(chain(rot(:Z), rot(:X), rot(:Z)) |> cache(2, recursive=true))

for i = 1:9
    push!(layers, cache(entangler(nbit, cnot_pair)))
    push!(layers, layer(nbit))
end

push!(layers, cache(entangler(nbit, cnot_pair)))

push!(layers, roll(nbit, chain(rot(:Z), rot(:X))))
circuit = chain(layers...)

import Base: empty!
function empty!(layers::Vector{MatrixBlock})
    for each in layers
        empty!(each)
    end
    layers
end

# for info in optimize(params->mmd_gradient(params,circuit, kernel, ptrain), )
#    println(info)
#    println("loss is ", params->loss_function(params, kernel, prob, ptrain))
#    clear_cache(circuit)
# end

loss_function(params, circuit, kernel, ptrain)

for i in 1:maxiter
    # loss_function(params, circuit, kernel, ptrain)
    gradient = mmd_gradient(params, circuit, kernel, ptrain)
    loss = loss_function(params, circuit, kernel, ptrain)
    println("$i step, loss = ", loss)

    # dispatch!(+, circuit, -learning_rate*gradient)
    # empty!(circuit)
end

# # write final parameters to file.
# params = gather_params(circuit)
# open("params.dat", "w") do io
#     writedlm(io, params)
# end
