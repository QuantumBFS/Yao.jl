using Compat.Test
include("qcbm.jl")

@testset "qcbm" begin
    num_layer = 5
    num_bit = 4
    circuit = diff_circuit(num_qubit, num_layer)
    kernel = hilbert_rbf_kernel(2, [0.3, 3.0], false)

    for info in optimize(mmd_gradient, args=(circuit, kernel, ptrain))
        println(info)
        println("loss is ", loss_function(kernel, prob, ptrain))
        clear_cache(circuit)
    end
end


