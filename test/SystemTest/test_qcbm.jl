using Compat.Test
using Gallium
include("qcbm.jl")

num_layer = 5
num_bit = 6
maxiter = 10
learning_rate = 0.1

circuit = diff_circuit(num_bit, num_layer)
kernel = hilbert_rbf_kernel(num_bit, [2.0], false)
params = zeros(nparam(circuit))
ptrain = randn(1<<num_bit)

#for info in optimize(params->mmd_gradient(params,circuit, kernel, ptrain), )
#    println(info)
#    println("loss is ", params->loss_function(params, kernel, prob, ptrain))
#    clear_cache(circuit)
#end
for i in 1:maxiter
    loss_function(params, circuit, kernel, ptrain)
    gradient = mmd_gradient(params, circuit, kernel, ptrain)
    loss = loss_function(params, circuit, kernel, ptrain)
    println("$i step, loss = ", loss)

    circuit |> add_params(-learning_rate*gradient) |> clear_cache
end

# write final parameters to file.
params = gather_params(circuit)
open("params.dat", "w") do io
    writedlm(io, params)
end
