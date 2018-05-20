using Compat.Test
include("QCBM.jl")

const nlayers = 10
const nbit = 9
const maxiter = 10
const learning_rate = 0.1

const kernel = RBFKernel(nbit, [2.0], false)
const params = vec(readdlm("theta-cl-bs.dat"))
const target = readdlm("wave_complex.dat")[:, 1] + im * readdlm("wave_complex.dat")[:, 2]
const ptrain = randn(1<<nbit)

cnot_pair = [
    (1, 7),
    (2, 8),
    (4, 7),
    (5, 3),
    (6, 0),
    (6, 3),
    (6, 7),
    (8, 5),
]

cnot_pair = map(x->(x[1]+1, x[2]+1), cnot_pair)

function entangler(n, pairs)
    seq = []
    for (c, uc) in pairs
        push!(seq, X(uc) |> C(c))
    end
    compose(seq)(n)
end

# circuit = make_circuit(nbit, nlayers)

const layer1 = chain(rot(:X), rot(:Z)) |> cache(2, recursive=true) |> roll
const layers = MatrixBlock[]
push!(layers, layer1(nbit))

layer = chain(rot(:Z), rot(:X), rot(:Z)) |> cache(2, recursive=true) |> roll

for i = 1:nlayers
    push!(layers, cache(entangler(nbit, cnot_pair)))
    push!(layers, layer(nbit))
end

circuit = chain(layers...)

import Base: empty!
function empty!(layers::Vector{MatrixBlock})
    for each in layers
        empty!(each)
    end
    seq
end

# #for info in optimize(params->mmd_gradient(params,circuit, kernel, ptrain), )
# #    println(info)
# #    println("loss is ", params->loss_function(params, kernel, prob, ptrain))
# #    clear_cache(circuit)
# #end
for i in 1:maxiter
    loss_function(params, circuit, kernel, ptrain)
    gradient = mmd_gradient(params, circuit, kernel, ptrain)
    loss = loss_function(params, circuit, kernel, ptrain)
    println("$i step, loss = ", loss)

    add_params!(circuit, -learning_rate*gradient)
    empty!(circuit)
end

# # write final parameters to file.
# params = gather_params(circuit)
# open("params.dat", "w") do io
#     writedlm(io, params)
# end
