using Compat.Test
include("QCBM.jl")

const nlayers = 5
const nbit = 6
const maxiter = 10
const learning_rate = 0.1

function entangler(n)
    seq = []
    for i = 1:n
        push!(seq, X(i) |> C(i % n + 1))
    end
    compose(seq)(n)
end

# circuit = make_circuit(nbit, nlayers)

const layer = chain(rot(:X), rot(:Z)) |> cache(2, recursive=true) |> roll
const layers = MatrixBlock[]
push!(layers, layer(nbit))

for i = 1:nlayers
    push!(layers, cache(entangler(nbit)))
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

kernel = RBFKernel(nbit, [2.0], false)
params = zeros((3 * nbit) * (nlayers - 1) + (2 * nbit))
ptrain = randn(1<<nbit)

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
