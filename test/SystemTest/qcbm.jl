using Compat.Test

# Interface
import QuCircuit: rotation_block
import QuCircuit: sequence
import mmd: kernel_expect, hilbert_rbf_kernel, mmd_loss

psi2prob(psi::Array) = real(conj(psi).*psi)

#=
cache_level (default=10)
    * 1-3, can cache (cached by default)
    * 4:9, cache becomes harder
    * 10, can not cache

if cache_signal (default=3) >= cache_level, then cache.

if user set cache_level, check if it is cacheable and cache/error.
=#
@testset "qcbm" begin
    num_layer = 5
    num_bit = 4

    # the entangle block
    entangle_block = chain(
                           c(2)(X(num_qubit, 1)),
                           c(4)(X(num_qubit, 3)),
                           c(3)(X(num_qubit, 2)),
                           c(4)(X(num_qubit, 1))
                          ) |> cache   # here, we use default level: 1

    # build the circuit
    circuit = sequence()
    for i in 1:num_layer
        if i!=0
            append!(circuit, entangle_block)
        end
        append!(circuit, rotation_block(num_bit, zxz_mask=[i!=0, true, i!=num_layer]) |> cache(recursive=true))
    end

    kernel = hilbert_rbf_kernel(2, [0.3, 3.0], false)

    for info in optimize(mmd_gradient, args=(circuit, kernel, ptrain))
        println(info)
        println("loss is ", loss_function(kernel, prob, ptrain))
        clear_cache(circuit)
    end
end

function run_circuit(params::Vector{Float64}, circuit::Sequence, signal::Int)
    psi = Register("0"^num_qubit)

    # >> returns iterator!
    # >> curry: cache_signal, scatter_params, mask_block
    for info in psi >> (circuit |> scatter_params(params) |> cache_signal(signal))   # here, cache signal uses default cache threshhold and can be avoided
        println("iblock = ", info["iblock"],
                ", current block = ", info["current"],
                ", next block = ", info["next"],
               )
        if info["cache_info"] == 1
            println("cached new value, it is ", info["cache"])
        elseif info["cache_info"] == 0
            println("used cached value, it is ", info["cache"])
        elseif info["cache_info"] == 2
            println("did not cache/use cached value")
        end
        if is_measure_block(info["current"])
            println("the measurement result is ", info["measure_res"])
        end

        #=  a possible way to hack the iteration
        if next_block == ...
            for psi >> info["next"]
                ...
            end
        end
        circuit |> mask_block(next_block)
        =#
    end
    return psi
end


"""
QCBM loss function.
    we can use
        samples = measure(psi, num_sample=20000)
    to get samples, here, we simply use the exact wave function.
"""
loss_function(params::Vector{Float64}, circuit::Sequence, kernel::Kernel, ptrain::Vector{Float64}) = run_circuit(params, circuit, 3) |> psi2prob |> mmd_loss(kernel, ptrain)

"""
QCBM gradient function.
"""
function mmd_gradient(params, circuit, kernel, ptrain)
    prob = run_circuit(params, circuit, 3) |> psi2prob

    function get1(i)
        params_ = copy(params)
        # pi/2 phase
        params_[i] += pi/2.
        prob_pos = run_circuit(params_, circuit, 0) |> psi2prob
        # -pi/2 phase
        params_[i] -= pi
        prob_neg = run_circuit(params_, circuit, 0) |> psi2prob

        grad_pos = kernel_expect(kernel, prob, prob_pos) - kernel_expect(kernel, prob, prob_neg)
        grad_neg = kernel_expect(kernel, p_data, prob_pos) - kernel_expect(kernel, p_data, prob_neg)
        return grad_pos - grad_neg
    end
    grad = mpido(get1, 1:length(theta_list))
    return grad
end
