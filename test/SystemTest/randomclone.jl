include("qcbm.jl")

@testset "randombasis qcbm" begin
    num_layer = 10
    num_bit = 6
    circuit = diff_circuit(num_bit, num_layer)
    psi_train = randn(1<<num_bit)
    train(circuit, psi_train)
end

"""
training a differenciable circuit to learn wave function.
"""
function train(circuit, psi_train)
    num_qubit = nqubit(circuit)
    # here random_params will not work
    rotbasis = RotBasis(num_qubit) |> random_basis |> mask(zeros(Bool, num_qubit*2)) |> cache
    circuit += rotbasis

    kernel = hilbert_rbf_kernel(2, [2.0], false)

    for info in optimize(mmd_gradient, args=(circuit, kernel, psi_train))
        println(info)
        println("loss is ", loss_function(kernel, prob, psi_train |> rot_basis |> psi2prob))

        # ready for next iteration
        clear_cache(circuit)
        rotbasis |> random_basis
    end
end
